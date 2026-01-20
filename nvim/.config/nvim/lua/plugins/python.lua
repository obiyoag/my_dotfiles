return {
  {
    "AstroNvim/astrolsp",
    opts = {
      servers = { "ruff", "pyright" },
      config = {
        ruff = {
          capabilities = {
            general = { positionEncodings = { "utf-16" } },
          },
          on_attach = function(client) client.server_capabilities.hoverProvider = false end,
        },
        pyright = {
          before_init = function(_, c)
            if not c.settings then c.settings = {} end
            if not c.settings.python then c.settings.python = {} end
            local root = c.root_dir or vim.fn.getcwd()
            local venv_py = root .. "/.venv/bin/python"
            c.settings.python.pythonPath = (vim.fn.filereadable(venv_py) == 1) and venv_py or vim.fn.exepath "python3"
          end,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoImportCompletions = true,
                diagnosticSeverityOverrides = {
                  reportUnusedImport = "information",
                  reportUnusedFunction = "information",
                  reportUnusedVariable = "information",
                  reportGeneralTypeIssues = "none",
                  reportOptionalMemberAccess = "none",
                  reportOptionalSubscript = "none",
                  reportPrivateImportUsage = "none",
                },
              },
            },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "python", "toml" })
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    specs = {
      {
        "mfussenegger/nvim-dap-python",
        dependencies = "mfussenegger/nvim-dap",
        ft = "python",
        config = function(_, opts)
          local root = vim.fn.getcwd()
          local venv_py = root .. "/.venv/bin/python"
          local path = (vim.fn.filereadable(venv_py) == 1) and venv_py or vim.fn.exepath "python3"

          require("dap-python").setup(path, opts)

          local dap = require "dap"

          local function read_json_file(file)
            if vim.fn.filereadable(file) ~= 1 then return nil end
            local lines = vim.fn.readfile(file)
            local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
            if not ok then return nil end
            return decoded
          end

          local function normalize_args(args)
            if type(args) ~= "table" then return nil end
            local out = {}
            for _, v in ipairs(args) do
              if type(v) == "string" then
                table.insert(out, v)
              else
                table.insert(out, tostring(v))
              end
            end
            return out
          end

          local function merge(defaults, overrides)
            local out = vim.deepcopy(defaults)
            if type(overrides) ~= "table" then return out end
            for k, v in pairs(overrides) do
              -- args 特判：确保是 string list
              if k == "args" then
                out.args = normalize_args(v) or out.args
              else
                out[k] = v
              end
            end
            return out
          end

          local function load_project_configs()
            local file = root .. "/debug_args.json"
            local decoded = read_json_file(file)
            if decoded == nil then return {} end

            -- 默认模板（你原来那些字段都放这里）
            local defaults = {
              type = "python",
              request = "launch",
              name = "Python: Launch (debug_args.json)",
              program = "${file}",
              cwd = "${workspaceFolder}",
              console = "integratedTerminal",
              justMyCode = false,
            }

            -- 支持两种格式：顶层就是一个 config；或 { configurations=[...] }
            if type(decoded.configurations) == "table" then
              local out = {}
              for _, cfg in ipairs(decoded.configurations) do
                table.insert(out, merge(defaults, cfg))
              end
              return out
            end

            return { merge(defaults, decoded) }
          end

          -- lua_ls 可能对 inject-field 报 warning，必要时取消注释下一行
          ---@diagnostic disable-next-line: inject-field
          dap.configurations.python = dap.configurations.python or {}

          -- 把项目配置插到最前面（优先显示）
          vim.schedule(function()
            local configs = load_project_configs()
            for i = #configs, 1, -1 do
              table.insert(dap.configurations.python, 1, configs[i])
            end
          end)
        end,
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
      format_on_save = {
        lsp_format = "fallback",
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    optional = true,
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      --------------------------------------------------------------------------
      -- 1. 基础 UI 设置（避免 scope 展开/跳动）
      --------------------------------------------------------------------------
      local ui_cfg = {
        expand_lines = false,
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.35 },
              { id = "stacks", size = 0.25 },
              { id = "breakpoints", size = 0.20 },
              { id = "watches", size = 0.20 },
            },
            size = 45, -- ✅ 固定宽度（列数）
            position = "right", -- ✅ 放右边，Neo-tree 一般在 left
          },
          {
            elements = { "repl", "console" },
            size = 12,
            position = "bottom",
          },
        },
      }
      dapui.setup(ui_cfg)

      --------------------------------------------------------------------------
      -- 2. 清理所有已有的 dapui / dapclient listeners（关键！！！）
      --------------------------------------------------------------------------
      local function clear_listeners(ev)
        for _, when in ipairs { "after", "before" } do
          local bucket = dap.listeners[when] and dap.listeners[when][ev]
          if bucket then
            for k, _ in pairs(bucket) do
              if type(k) == "string" then
                local lk = string.lower(k)
                if string.find(lk, "dapui", 1, true) or string.find(lk, "dapclient", 1, true) then bucket[k] = nil end
              end
            end
          end
        end
      end

      for _, ev in ipairs {
        "event_initialized",
        "event_terminated",
        "event_exited",
        "event_stopped",
      } do
        clear_listeners(ev)
      end

      --------------------------------------------------------------------------
      -- 3. 只注册你自己的一套 listeners（稳定、不跳）
      --------------------------------------------------------------------------

      -- 只在真正开始调试时打开 UI
      dap.listeners.after.event_initialized["user_dapui"] = function() dapui.open() end

      -- ❌ 不在 stopped 里做任何事情（这是“跳来跳去”的根源）
      dap.listeners.after.event_stopped["user_dapui"] = nil

      -- 结束时：确认 session 真没了再关 UI（防子进程抖动）
      local function close_if_no_session()
        vim.schedule(function()
          if dap.session() == nil then dapui.close() end
        end)
      end

      dap.listeners.before.event_terminated["user_dapui"] = close_if_no_session
      dap.listeners.before.event_exited["user_dapui"] = close_if_no_session
    end,
  },
}
