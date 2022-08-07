local util = require('roadrunner.util')
local defaults = require('roadrunner.defaults')

__RoadRunner = __RoadRunner
    or {
        buf = require('roadrunner.buf'),
        runner = require('roadrunner.runner'),
    }

local M = __RoadRunner

M.setup = function(opts)
    opts = opts or {}
    if M.setup_called then
        return
    end

    M.opts = vim.tbl_deep_extend('keep', opts, defaults)
    M.setup_called = true
    M.create_commands()
end

M.create_commands = function()
    vim.api.nvim_create_user_command('Run', function(opts)
        if #opts.fargs == 0 then
            print('Please enter a command to run')
            return
        end
        M.roadrunner(opts.fargs)
    end, {
        nargs = '*',
    })

    vim.api.nvim_create_user_command('StopRun', function()
        vim.api.nvim_del_augroup_by_name('RoadRunner')
        M.buf.delete()
    end, {})
end

-- Core logic.
M._run = function(command)
    local cmd, cwd = util.parse_command(command), util.get_cwd(command)

    M.buf.open_scratch()

    M.runner.start_timer(M.buf.id, cmd)
    return M.runner.start_job(M.buf.id, cmd, cwd)
end

-- Entrypoint.
M.roadrunner = function(command)
    M.buf.cmd_group = vim.api.nvim_create_augroup('RoadRunner', {})

    local ok = M._run(command)

    if M.opts.on_save and ok then
        vim.api.nvim_create_autocmd('BufWritePost', {
            group = M.buf.cmd_group,
            buffer = vim.api.nvim_get_current_buf(),
            callback = function()
                if not M.buf.is_visible then
                    return
                end
                M._run(command)
            end,
        })
    end
end

return M
