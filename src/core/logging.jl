const _LOGGER = Ref{Logging.ConsoleLogger}()

"""
    silence(; all_levels = false)

Silence logging within PowerModelsACDC, PowerModels and InfrastructureModels.

By default, error-level messages remain enabled; this is equivalent to calling
`logger_config!("error")` for all three packages.
Set `all_levels = true` to silence all log messages, including errors.
"""
function silence(; all_levels::Bool = false)
    log_level = all_levels ? Logging.AboveMaxLevel : "error"
    logger_config!(log_level)
    _PM.logger_config!(log_level)
    _IM.logger_config!(log_level)
    return
end

function _meta_formatter(level::Logging.LogLevel, _module, args...)
    return Logging.default_logcolor(level), "$(_module) | $level]:", ""
end

function logger_config!(level::Logging.LogLevel)
    _LOGGER[] =
        Logging.ConsoleLogger(stdout, level; meta_formatter = _meta_formatter)
    return
end

"""
    logger_config!(level::String)

Set the logging level within PowerModelsACDC. `level` must be one of `"error"`,
`"warn"`, `"info"`, or `"debug"`.
"""
function logger_config!(level::String)
    return getfield(Logging, level |> titlecase |> Symbol) |> logger_config!
end

function _log_if_level(f, level, logger = _LOGGER[])
    if level >= Logging.min_enabled_level(logger)
        Logging.with_logger(f, logger)
    end
    return
end

macro _error(msg)
    return quote
        $_log_if_level(() -> @error($msg), $(Logging.Error))
        error($msg)
    end |> esc
end

macro _warn(msg)
    return :($_log_if_level(() -> @warn($msg), $(Logging.Warn))) |> esc
end

macro _debug(msg)
    return :($_log_if_level(() -> @debug($msg), $(Logging.Debug))) |> esc
end

macro _info(msg)
    return :($_log_if_level(() -> @info($msg), $(Logging.Info))) |> esc
end
