-- following code by Jenssons. I just removed the redundant sound :) (no seriously, why does it have the sound when it's emitted from the function that sends the message)

local confetti = Material("confetti.png")

net.Receive("TTT2JimboConfetti", function()
	local ent = net.ReadEntity()

	if not IsValid(ent) then return end

	local pos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z)

	if ent.GetShootPos then
		pos = ent:GetShootPos()
	end

	local velMax = 200
	local gravMax = 50

	local gravity = Vector(math.random(-gravMax, gravMax), math.random(-gravMax, gravMax), math.random(-gravMax, 0))

	--Handles particles
	local emitter = ParticleEmitter(pos, true)

	for i = 1, 150 do
		local p = emitter:Add(confetti, pos)
		p:SetStartSize(math.random(6, 10))
		p:SetEndSize(0)
		p:SetAngles(Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)))
		p:SetAngleVelocity(Angle(math.random(5, 50), math.random(5, 50), math.random(5, 50)))
		p:SetVelocity(Vector(math.random(-velMax, velMax), math.random(-velMax, velMax), math.random(-velMax, velMax)))
		p:SetColor(255, 255, 255)
		p:SetDieTime(math.random(4, 7))
		p:SetGravity(gravity)
		p:SetAirResistance(125)
	end
end)