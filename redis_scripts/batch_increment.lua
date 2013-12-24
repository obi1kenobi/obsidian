local res

for w in string.gmatch(ARGV[1], "%w+") do
  redis.call('setnx', w, 0)
  res = redis.call('incr', w)
end

return res
