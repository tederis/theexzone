--[[
	Hash
]]
function _hashFn( str )
	local result = 0
	for i = 1, string.len( str ) do
		local byte = string.byte( str, i )
		result = byte + bitLShift( result, 6 ) + bitLShift( result, 16 ) - result
	end
	return result
end