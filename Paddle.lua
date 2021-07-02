--[[
    GD50 2018
    Pong Remake

    -- Paddle Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a paddle that can move up and down. Used in the main
    program to deflect the ball back toward the opponent.
]]

Paddle = Class{}

--[[
    The `init` function on our class is called just once, when the object
    is first created. Used to set up all variables in the class and get it
    ready for use.

    Our Paddle should take an X and a Y, for positioning, as well as a width
    and height for its dimensions.

    Note that `self` is a reference to *this* object, whichever object is
    instantiated at the time this function is called. Different objects can
    have their own x, y, width, and height values, thus serving as containers
    for data. In this sense, they're very similar to structs in C.
]]
function Paddle:init(x, y, width, height, FRICTION, colour)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dx = 0
    self.dy = 0
    self.d2y = 0
    self.d2x = 0
    self.FRICTION = FRICTION
    self.colour = colour
end

function Paddle:update(dt)
    -- math.max here ensures that we're the greater of 0 or the player's
    -- current calculated Y position when pressing up so that we don't
    -- go into the negatives; the movement calculation is simply our
    -- previously-defined paddle speed scaled by dt
    self.dy = PADDLE_FRICTION_FACTOR * self.dy
    self.dx = PADDLE_FRICTION_FACTOR * self.dx
    self.dy = self.d2y * dt + self.dy
    self.dx = self.d2x * dt + self.dx
    if self.dy < 0 then
      sign = -1
    elseif self.dy > 0 then
      sign = 1
    else
      sign = 0
    end
    -- self.d2y = sign * (math.abs(self.d2y) - self.FRICTION * dt)
    self.dy = self.dy + self.d2y * dt
    if self.dy < 0 then
        self.y = self.y + self.dy * dt
        -- if self.y == 0 then
        --   self.dy = 0
        --   -- self.d2y = 0
        -- end
    -- similar to before, this time we use math.min to ensure we don't
    -- go any farther than the bottom of the screen minus the paddle's
    -- height (or else it will go partially below, since position is
    -- based on its top left corner)
    else
        self.y = self.y + self.dy * dt
        -- if self.y == VIRTUAL_HEIGHT - self.height then
        --   self.dy = 0
        -- end
    end

    if self.dx < 0 then
      self.x = self.x + self.dx * dt
    elseif self.dx > 0 then
      self.x = self.x + self.dx * dt
    else
      -- lol
    end

    if self.x + self.width< 0 then
      self.x = VIRTUAL_WIDTH
    elseif self.x > VIRTUAL_WIDTH then
      self.x = 0 - self.width
    end

    if self.y + self.height < 0 then
      self.y = VIRTUAL_HEIGHT
    elseif self.y > VIRTUAL_HEIGHT then
      self.y = 0 - self.height
    end

end

--[[
    To be called by our main function in `love.draw`, ideally. Uses
    LÖVE2D's `rectangle` function, which takes in a draw mode as the first
    argument as well as the position and dimensions for the rectangle. To
    change the color, one must call `love.graphics.setColor`. As of the
    newest version of LÖVE2D, you can even draw rounded rectangles!
]]
function Paddle:render()
    love.graphics.setColor(self.colour)
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    love.graphics.setColor(255, 255, 255, 255)
end
