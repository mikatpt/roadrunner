local M = {}

M.start_timer = function(bufnr, cmd)
    M.cmd_complete = false
    local timer = vim.loop.new_timer()
    local elapsed, interval = 0, 200

    local msg = string.format('[%02d:%02d] Running command %s...', 0, 0, cmd)

    -- Set initial message and clear all previously run commands.
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { msg, '' })

    timer:start(
        0,
        interval,
        vim.schedule_wrap(function()
            if M.cmd_complete or elapsed > 1000 * 60 * 2 then
                pcall(timer.close, timer)
            end

            local minutes = math.floor(elapsed / 60000)
            local seconds = (elapsed - (minutes * 60000)) / 1000

            local format = '[%02d:%02d] Running command `%s`...'
            if M.cmd_complete == true then
                format = '[%02d:%02d] Finished running command `%s`.'
            elseif elapsed > 1000 * 60 * 2 then
                format = '[%02d:%02d] Timed out command after 2 minutes: `%s`'
            end

            local new_msg = string.format(format, minutes, seconds, cmd)

            if new_msg ~= msg then
                vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { new_msg })
                msg = new_msg
            end

            elapsed = elapsed + interval
        end)
    )
end

--- Returns true if successful.
--- @return boolean
M.start_job = function(bufnr, cmd, cwd)
    M.stop_job()

    local options = {
        cwd = cwd,
        on_stdout = function(_, lines)
            vim.schedule(function()
                for _, value in pairs(lines) do
                    if value ~= '' then
                        vim.api.nvim_buf_set_lines(bufnr, 2, -1, false, { value })
                    end
                end
            end)
        end,
        on_stderr = function(_, lines)
            vim.schedule(function()
                for _, value in pairs(lines) do
                    if value ~= '' then
                        vim.api.nvim_buf_set_lines(bufnr, 2, -1, false, { value })
                    end
                end
            end)
        end,
        on_exit = function(_, code)
            M.cmd_complete = true

            if code == 127 then
                local value = '...Looks like cmd `' .. cmd .. "` isn't executable?"
                vim.api.nvim_buf_set_lines(bufnr, 2, -1, false, { value })
            end
        end,
    }

    local job = vim.fn.jobstart(cmd, options)
    if job == -1 then
        vim.notify('ERROR: ' .. cmd .. ' is not executable!', vim.log.levels.ERROR)
        return false
    elseif job == 0 then
        vim.notify('ERROR: invalid arguments in vim.fn.jobstart!', vim.log.levels.ERROR)
        return false
    end

    M.job = job

    return true
end

M.stop_job = function()
    if M.job then
        vim.fn.jobstop(M.job)
        M.job = nil
    end
end

return M
