require 'strangepan.secretary.PhysObject'
require 'strangepan.util.class'
require 'strangepan.util.type'
local Translation = require 'mazerino.util.translation'
local Orientation = require 'mazerino.util.orientation'

local Door = buildClass(Wall)

function Door:_init()
  Door.superclass._init(self)
  self.orientation = Orientation.HORIZONTAL
  self.open = false
  self.openness = 0
end

function Door:setOrientation(orientation)
  assertInteger(orientation)
  assert(Orientation.fromId(orientation) ~= nil, 'Orientation not recognized: '..orientation)

  self.orientation = orientation
  return self
end

function Door:onStep()
  Door.superclass.onStep(self)
  if self.open then
    if self.openness > 0.95 then
      self.openness = 1
    else
      self.openness = self.openness + 0.05
    end
  else
    if self.openness < 0.05 then
      self.openness = 0
    else
      self.openness = self.openness - 0.05
    end
  end
end

function Door:setOpen(open)
  self.open = assertBoolean(open)
  return self
end

function Door:draw()
  love.graphics.push()
  love.graphics.setColor(255, 255, 255)
  local x, y = Translation.toScreen(self:getPosition())
  local w, h = Translation.toScreen(self:getSize())
  local w2 = w/2  -- width half
  local h2 = h/2  -- height half
  love.graphics.translate(x + w2, y + h2)
  love.graphics.scale(self.drawScale)

  if self.orientation == Orientation.HORIZONTAL then
    local wo = w2 * (1 - self.openness)  -- part of half of door visible when opening
    love.graphics.rectangle("fill", -w2, -h2, wo, h)  -- left wall
    love.graphics.rectangle("fill", w2-wo, -h2, wo, h)  -- right wall
  elseif self.orientation == Orientation.VERTICAL then
    local ho = h2 * (1 - self.openness)  -- part of half of door visible when opening
    love.graphics.rectangle("fill", -w2, -h2, w, ho)  -- top wall
    love.graphics.rectangle("fill", -w2, h2-ho, w, ho)  -- bottom wall
  end

  love.graphics.pop()
end

return Door