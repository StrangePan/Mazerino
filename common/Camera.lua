require "strangepan.secretary.Entity"
require "strangepan.secretary.PhysObject"
require "strangepan.util.type"
local translation = require "mazerino.util.translation"

--
-- Camera class for handling motion and keeping a subject within view.
--
Camera = buildClass(Entity)
local Class = Camera

function Class:_init()
  Class.superclass._init(self)
  
  self.x = 0
  self.y = 0
  self.drawX = self.x
  self.drawY = self.y
  
  self.subject = nil
  self.snapThreshold = 0.0078125 -- 1/128
  self.easeRatio = 0.25
end

--
-- Sets the camera's target coordinates. It will move towards these coordinates
-- over multiple draw cycles at an ease value set with `setEasing()`.
--
function Class:moveTowards(x, y)
  self.x = assertNumber(x, "x")
  self.y = assertNumber(y, "y")
end

--
-- Immediately moves the camera to the specified coordinates.
--
function Class:jumpTo(x, y)
  self:moveTowards(x, y)
  self.drawX = self.x
  self.drawY = self.y
end

--
-- Immediately moves camera to be centered on the specified subject.
--
function Class:jumpToSubject(subject)
  assertClass(subject, PhysObject, "subject")
  local px, py = translation.toScreen(subject:getPosition())
  local pw, ph = translation.toScreen(subject:getSize())
  self:jumpTo(px + pw / 2, py + ph / 2)
end

--
-- Sets the Camera subject for this camera to track or `nil` to remove the
-- current subject. Must be of type PhysObject.
--
function Class:setSubject(subject)
  if not subject then
    self.subject = nil
    return
  end
  self.subject = assertClass(subject, PhysObject, "subject")
end

--
-- Sets the easing value of the camera. This is the ratio at which it approaches
-- its target coordinates. Higher values cause the camera to snap to the target
-- faster. The supplied ease ratio must be a number greater than 0 and less than
-- or equal to 1.
--
function Class:setEasing(easeRatio)
  assertNumber(easeRatio)
  assert(0 < easeRatio and easeRatio <= 1, "number must be (0..1]")
  self.easeRatio = easeRatio
end

function Class:registerWithSecretary(secretary)
  Camera.superclass.registerWithSecretary(self, secretary)
  secretary:registerEventListener(self, self.onPreDraw, EventType.PRE_DRAW)
  secretary:registerEventListener(self, self.onPostPhysics, EventType.POST_PHYSICS)
  secretary:registerEventListener(self, self.onStep, EventType.STEP)
  return self
end

--
-- Translates the drawing area to give the illusion of a camera moving.
--
function Class:onPreDraw()
  love.graphics.origin()
  local width, height = love.graphics.getDimensions()
  love.graphics.translate((width/2)-self.drawX, (height/2)-self.drawY)
end

--
-- Moves the camera one step towards the subject.
--
function Class:onPostPhysics()
  self:stepTowardsSubject()
end

--
-- Eases `value` towards `target` with an easing ratio of `ease` and a snapping
-- threshold of `thresh`. All parameters are numbers.
--
local function easeValue(value, target, ease, thresh)
  if math.abs(target - value) < thresh then
    return target
  else
    return value - (value - target) * ease
  end
end

--
-- Moves the camera one step towards the subject.
--
function Class:stepTowardsSubject()
  self.drawX = easeValue(self.drawX, self.x, self.easeRatio, self.snapThreshold)
  self.drawY = easeValue(self.drawY, self.y, self.easeRatio, self.snapThreshold)
end

--
-- Moves the camera's target coordinates to centered on the subject.
--
function Class:onStep()
  if not self.subject then
    return
  end
  
  local ox,oy = translation.toScreen(self.subject:getPosition())
  local ow,oh = translation.toScreen(self.subject:getSize())
  
  self.x = ox + ow/2
  self.y = oy + oh/2
end

function Class:destroy()
  Class.superclasss.destroy(self)
  self.subject = nil
end
