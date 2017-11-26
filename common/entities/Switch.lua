require "strangepan.secretary.PhysObject"
require "Color"
require "strangepan.util.type"
local Door = require "entities.Door"
local translation = require "mazerino.util.translation"

Switch = buildClass(PhysObject)

function Switch:_init(x, y)
  Switch.superclass._init(self)
  self:setPosition(x, y)
  self:setSize(1, 1)
  self.lineColor = Color(255, 255, 255)
  self.offColor = Color(255, 0, 0, 255*2/4)
  self.onColor = Color(0, 255, 0, 255*2/4)
  
  self.active = false
  self.activeTimer = 0
end

function Switch:activate()
  self.active = true
  self.activeTimer = 300

  local x, y = self:getPosition()
  x = x - 2
  local collisions = self.secretary:getCollisions(y, x + 1, y + 1, x)
  for _,entity in ipairs(collisions) do
    if checkType(entity, Door) then
      entity:setOpen(true)
    end
  end
end

function Switch:deactivate()
  self.active = false
  self.activeTimer = 0

  local x, y = self:getPosition()
  x = x - 2
  local collisions = self.secretary:getCollisions(y, x + 1, y + 1, x)
  for _,entity in ipairs(collisions) do
    if checkType(entity, Door) then
      entity:setOpen(false)
    end
  end
end

function Switch:registerWithSecretary(secretary)
  Switch.superclass.registerWithSecretary(self, secretary)
  secretary:registerEventListener(self, self.step, EventType.STEP)
  secretary:registerEventListener(self, self.postStep, EventType.POST_STEP)
  secretary:registerEventListener(self, self.draw, EventType.DRAW)
end

function Switch:step()
  if self.activeTimer > 0 then
    self.activeTimer = self.activeTimer - 1
    if self.activeTimer == 0 then
      self:deactivate()
    end
  end
end

function Switch:postStep()
  local t, r, b, l = self:getBoundingBox()
  if table.getn(self:getSecretary():getCollisions(t, r, b, l, Actor)) > 0 then
    self:activate()
  end
end

function Switch:draw()
  love.graphics.push()
  local x, y = translation.toScreen(self:getPosition())
  local w, h = translation.toScreen(self:getSize())
  local ow = w/2
  local oh = h/2
  local scale = 13/16
  local innerScale = 3/8
  local outerWidth = 3/32
  love.graphics.translate(x + ow, y + oh)
  love.graphics.scale(scale)
  
  -- inner translucent section
  if self.active then
    love.graphics.setColor(self.onColor:getRGBA())
  else
    love.graphics.setColor(self.offColor:getRGBA())
  end
  love.graphics.rectangle("fill", -ow, -oh, w, h)
  
  -- outline and inner box
  local t = outerWidth -- line thickness
  love.graphics.setColor(self.lineColor:getRGBA())
  love.graphics.rectangle("fill", -ow, -oh, w, h*t) -- top
  love.graphics.rectangle("fill", -ow, -oh+h*t, w*t, h-2*h*t) -- left
  love.graphics.rectangle("fill", -ow+w-w*t, -oh+h*t, w*t, h-2*h*t) -- right
  love.graphics.rectangle("fill", -ow, -oh+h-h*t, w, h*t) -- bottom
  love.graphics.rectangle("fill", -ow * innerScale, -oh * innerScale, w * innerScale, h * innerScale)
  
  love.graphics.pop()
end
