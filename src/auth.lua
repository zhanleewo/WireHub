local packet = require('packet')

local M = {}

function M.update(n, a, deadlines)
    -- still searching?
    if not a.p then
        return
    end

    local deadline = a.req_ts+a.retry+1

    if now >= deadline then
        if a.retry > wh.AUTH_RETRY then
            return a:cb(false, "could not auth")
        end

        n:_sendto{
            dst=a.p,
            m=packet.auth(n, a.p),
            sk=a.alias_sk,
        }

        a.retry = a.retry + 1
        a.req_ts = now
        a.last_seen = now

        deadline = a.req_ts+a.retry+1
    end

    deadlines[#deadlines+1] = deadline
end

function M.resolve_alias(n, alias, src)
    -- alias may be nil

    if alias then
        -- copy all attributes of alias to p
        src.relay = nil
        for k, v in pairs(alias) do
            if k ~= 'k' and k ~= 'alias' then
                src[k] = alias[k]
            end
        end

        alias.alias = src.k
    end
end

function M.on_authed(n, alias_k, src)
    for a in pairs(n.auths) do
        if a.alias_k == alias_k then
            local alias = n.kad:get(alias_k)

            M.resolve_alias(n, alias, n.p)

            return a:cb(true)
        end
    end
end

return M

