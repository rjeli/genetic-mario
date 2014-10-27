local socket = require("socket")

INITIAL_SCREEN_VAL = 0x18
SCREEN_BYTE = 0x06A0
LIVES_SCREEN_BYTE = 0x0757

SCORE_BYTE_1 = 0x07DE
SCORE_BYTE_2 = 0x07DF
SCORE_BYTE_3 = 0x07E0
SCORE_BYTE_4 = 0x07E1
SCORE_BYTE_5 = 0x07E2

SPEED = "maximum"

NET_A = 		0x01
NET_B = 		0x02
NET_LEFT = 	0x04
NET_RIGHT = 0x08
NET_UP = 		0x10
NET_DOWN = 	0x20

print(_VERSION)
print(socket._VERSION)

local host, port = "localhost", 5000

-- emu.speedmode(SPEED)
emu.softreset()

-- controller
local joy = {}

-- start game
for i=1,60 do
	emu.frameadvance()
end
joy["start"] = true
joypad.set(1, joy)
joy["start"] = false
for i=1,160 do
	emu.frameadvance()
end
-- initial savestate creation
local origin = savestate.object()
savestate.save(origin)
savestate.persist(origin)

offsetByte = 0x18
currentOffset = 0x00

holdA = 0

function frame()
	local connection = socket.connect(host, port)
	if connection == nil then
		print('could not connect to server')
	end

	currentOffset = memory.readbyte(SCREEN_BYTE)
	if currentOffset == ((offsetByte+1) % 32) then
		offsetByte = offsetByte + 1
	end

	gui.text(10, 10, currentOffset)
	gui.text(10, 20, offsetByte)

	if memory.readbyte(LIVES_SCREEN_BYTE) == 1 then
		connection:send(tostring(
			memory.readbyte(SCORE_BYTE_5) +
			memory.readbyte(SCORE_BYTE_4) * 10 +
			memory.readbyte(SCORE_BYTE_3) * 100 +
			memory.readbyte(SCORE_BYTE_2) * 1000 +
			memory.readbyte(SCORE_BYTE_1) * 10000 +
			offsetByte * 15
		))
		savestate.load(origin)
		offsetByte = 0x18
		currentOffset = 0x00
		connection:close()
		connection = socket.connect(host, port)
		if connection == nil then
			print('could not connect to server')
		end
	end


	connection:send("req")
	local res = connection:receive(1)

	res = string.byte(res)

	if holdA > 0 then holdA = holdA + 1 end

--	joy["A"] = (AND(res, NET_A) ~= 0) and (holdA < 60)
	if AND(res, NET_A) ~= 0 then
		if holdA == 0 then holdA = holdA + 1 end
	end
	joy["A"] = (holdA < 30)
	joy["B"] = (AND(res, NET_B) ~= 0)
	joy["up"] = (AND(res, NET_UP) ~= 0)
	joy["down"] = (AND(res, NET_DOWN) ~= 0)
	joy["left"] = (AND(res, NET_LEFT) ~= 0)
	joy["right"] = (AND(res, NET_RIGHT) ~= 0)

	if holdA > 60 then holdA = 0 end

	joypad.set(1, joy)

	connection:close()
end

emu.registerbefore(frame)

-- while true do
-- 	savestate.load(origin)
-- 	-- initial screen position
-- 	offsetByte = 0x18
-- 
-- 	while memory.readbyte(LIVES_SCREEN_BYTE) == 0 do
-- 		pause = true
-- 
-- 		recvt, sendt, err = socket.select({server}, {}, 0)
-- 		if next(recvt) ~= nil then
-- 			local client = server:accept()
-- 			client:settimeout(0)
-- 			local line, err = client:receive()
-- 			if not err then 
-- 				client:send(line .. "\n")
-- 				print(line) 
-- 				if line == "jump" then
-- 					joy["A"] = true
-- 					jumped = true
-- 					pause = false
-- 				end
-- 				if line == "step" then
-- 					pause = false
-- 				end
-- 			end
-- 			client:close()
-- 		end
-- 
-- 
-- 		currentOffset = memory.readbyte(SCREEN_BYTE)
-- 		gui.text(10, 10, string.format("%x", currentOffset))
-- 
-- 		if currentOffset == ((offsetByte+1) % 32) then
-- 			offsetByte = offsetByte + 1
-- 		end
-- 
-- 		gui.text(10, 20, string.format("%x", offsetByte))
-- 		gui.text(10, 30, string.format("%x", memory.readbyte(SCORE_BYTE_1)))
-- 		gui.text(10, 40, string.format("%x", memory.readbyte(SCORE_BYTE_2)))
-- 		gui.text(10, 50, string.format("%x", memory.readbyte(SCORE_BYTE_3)))
-- 		gui.text(10, 60, string.format("%x", memory.readbyte(SCORE_BYTE_4)))
-- 		gui.text(10, 70, string.format("%x", memory.readbyte(SCORE_BYTE_5)))
-- 
-- 		if pause then sleep(0.01) else emu.frameadvance() end
-- 
-- 		joypad.set(1, joy)
-- 		if jumped then joy["A"] = false end
-- 	end
-- end
