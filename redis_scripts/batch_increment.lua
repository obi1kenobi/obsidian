local res = redis.call('exists', ARGV[1])

if res == 0 then
  redis.call('set', ARGV[1], ARGV[2])

  for w in string.gmatch(ARGV[3], "[^|]+") do
    redis.call('setnx', w, 0)
    res = redis.call('incr', w)
  end
end

return res
