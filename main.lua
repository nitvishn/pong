--[[
    GD50 2018
    Pong Remake

    -- Main Program --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally programmed by Atari in 1972. Features two
    paddles, controlled by players, with the goal of getting
    the ball past your opponent's edge. First to 10 points wins.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on
    modern systems.
]]

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'push'

-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- our Paddle class, which stores position and dimensions for each Paddle
-- and the logic for rendering them
require 'Paddle'

-- our Ball class, which isn't much different than a Paddle structure-wise
-- but which will mechanically function very differently
require 'Ball'

-- size of our actual window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- size we're trying to emulate with push
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

FRICTION_FACTOR = 0.99
PADDLE_FRICTION_FACTOR = 0.95

-- paddle movement speed
PADDLE_SPEED = 500
FRICTION = 1000
WIN_SCORE = 15

GRAVITY = 0

SPEED_FACTOR = 1.03

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()
    -- set love's default filter to "nearest-neighbor", which essentially
    -- means there will be no filtering of pixels (blurriness), which is
    -- important for a nice crisp, 2D look
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set the title of our application window
    love.window.setTitle('Pong')

    -- seed the RNG so that calls to random are always random
    math.randomseed(os.time())

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    -- set up our sound effects; later, we can just index this table and
    -- call each entry's `play` method
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })

    -- initialize our player paddles; make them global so that they can be
    -- detected by other functions and modules
    player1 = Paddle(10, 30, 5, 20, FRICTION, {255, 0, 0, 255})
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20, FRICTION, {0, 0, 255, 255})

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- initialize score variables
    player1Score = 0
    player2Score = 0

    -- either going to be 1 or 2; whomever is scored on gets to serve the
    -- following turn
    servingPlayer = 1

    -- player who won the game; not set to a proper value until we reach
    -- that state in the game
    winningPlayer = 0

    -- the state of our game; can be any of the following:
    -- 1. 'start' (the beginning of the game, before first serve)
    -- 2. 'serve' (waiting on a key press to serve the ball)
    -- 3. 'play' (the ball is in play, bouncing between paddles)
    -- 4. 'done' (the game is over, with a victor, ready for restart)
    gameState = 'start'
end

--[[
    Called whenever we change the dimensions of our window, as by dragging
    out its bottom corner, for example. In this case, we only need to worry
    about calling out to `push` to handle the resizing. Takes in a `w` and
    `h` variable representing width and height, respectively.
]]
function love.resize(w, h)
    push:resize(w, h)
end

function realloc_dy(ball)
  ball.dy = - 1 * GRAVITY
  -- if ball.dy < 0 then
  --     ball.dy = -ball.dy
  --     -- ball.dy = -math.random(10, 150)
  -- else
  --     ball.dy = -ball.dy
  --     -- ball.dy = math.random(10, 150)
  -- end
end

function realloc_dx(ball)
  ball.dx = -ball.dx * SPEED_FACTOR
end

function rebound(ball, paddle)
  print("DETECTED.")
  print(ball.x, ball.dx, ball.width, paddle.x, paddle.dx, paddle.width)

  -- if ball.y < paddle.y then
  --   print('above')
  --   ball.y = ball.y - ball.width/2
  --   ball.dy = - ball.dy
  -- elseif ball.y + ball.height > paddle.y + paddle.height then
  --   print('below')
  --   ball.y = ball.y + ball.width/2
  --   ball.dy = - ball.dy
  --   realloc_dx(ball)
  -- if (ball.x < paddle.x) then
  --   print('left')
  --   ball.dx = - math.abs(ball.dx)
  --   realloc_dy(ball)
  --   -- ball.x = ball.x - ball.width/2
  -- elseif (ball.x + ball.width > paddle.x + paddle.width) then
  --   print('right')
  --   ball.dx = math.abs(ball.dx)
  --   realloc_dy(ball)
  --   ball.x = ball.x + ball.width/2
  -- end
  realloc_dy(ball)
  -- if ball.dx < 0 and paddle.dx < 0 then
  --   ball.dx = math.min(paddle.dx, ball.dx)
  --   ball.x = ball.x - ball.width/2
  -- elseif ball.dx > 0 and paddle.dx > 0 then
  --   ball.dx = math.max(paddle.dx, ball.dx)
  --   ball.x = ball.x + ball.width/2
  -- else
  --   ball.dx = - ball.dx
  --   if ball.dx > 0 and paddle.dx < 0 then
  --     ball.x = ball.x - ball.width/2
  --   elseif ball.dx < 0 and paddle.dx > 0 then
  --     ball.x = ball.x + ball.width/2
  --   elseif ball.dx == 0 then
  --     ball.dx = paddle.dx
  --   end
  -- end
  if not (paddle.dx == 0 and paddle.dy == 0) then
    ball.dx = 1.5 * paddle.dx
    ball.dy = 1.5 * paddle.dy
  else
    ball.dx = -ball.dx
  end
end

function resetPositions()
  player1.x = 10
  player1.y = 30
  player1.d2x = 0
  player1.d2y = 0
  player1.dx = 0
  player1.dy = 0

  player2.d2x = 0
  player2.d2y = 0
  player2.dx = 0
  player2.dy = 0
  player2.x = VIRTUAL_WIDTH - 10
  player2.y = VIRTUAL_HEIGHT - 30
end
--[[
    Called every frame, passing in `dt` since the last frame. `dt`
    is short for `deltaTime` and is measured in seconds. Multiplying
    this by any changes we wish to make in our game will allow our
    game to perform consistently across all hardware; otherwise, any
    changes we make will be applied as fast as possible and will vary
    across system hardware.
]]
function love.update(dt)
    if gameState == 'serve' then
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = -math.random(70, 100)
        else
            ball.dx = math.random(70, 100)
        end
    elseif gameState == 'play' then
        -- detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on the position
        -- at which it collided, then playing a sound effect
        if ball:collides(player1) then
            rebound(ball, player1)

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            rebound(ball, player2)
            -- ball.dx = -ball.dx * SPEED_FACTOR
            -- ball.x = player2.x - 4
            --
            -- -- keep velocity going in the same direction, but randomize it
            -- if ball.dy < 0 then
            --     -- ball.dy = -ball.dy
            --     ball.dy = math.random(10, 150)
            -- else
            --     -- ball.dy = -ball.dy
            --     ball.dy = math.random(10, 150)
            -- end
            -- -- if ball.dy < 0 then
            -- --     ball.dy = -math.random(10, 150)
            -- -- else
            -- --     ball.dy = math.random(10, 150)
            -- -- end

            sounds['paddle_hit']:play()
        end

        -- detect upper and lower screen boundary collision, playing a sound
        -- effect and reversing dy if true
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- if we reach the left or right edge of the screen, go back to serve
        -- and update the score and serving player
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            resetPositions()
            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score == WIN_SCORE then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            resetPositions()
            if player1Score == WIN_SCORE then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end

    --
    -- paddles can move no matter what state we're in
    --
    -- player 1
    -- if ball.y > player1.y + player1.width then
    if gameState == 'play' then
      if love.keyboard.isDown('s') then
          player1.d2y = PADDLE_SPEED
      elseif love.keyboard.isDown('w') then
      -- elseif ball.y < player1.y + player1.width then
          player1.d2y = -PADDLE_SPEED
      else
        player1.d2y = 0
      end
      if love.keyboard.isDown('a') then
          player1.d2x = -PADDLE_SPEED
      elseif love.keyboard.isDown('d') then
          player1.d2x = PADDLE_SPEED
      else
          player1.d2x = 0
      end
      -- player1.y = ball.y

      if love.keyboard.isDown('up') then
          player2.d2y = -PADDLE_SPEED
      elseif love.keyboard.isDown('down') then
      -- elseif ball.y < player1.y + player1.width then
          player2.d2y = PADDLE_SPEED
      else
        player2.d2y = 0
      end
      if love.keyboard.isDown('left') then
          player2.d2x = -PADDLE_SPEED
      elseif love.keyboard.isDown('right') then
          player2.d2x = PADDLE_SPEED
      else
          player2.d2x = 0
      end

    -- AI CODE
        -- if ball.dx >= 0 then
        --     if ball.dx == 0 and ball.dy == 0 and collides(ball, player2) then
        --         player2.d2x = - PADDLE_SPEED
        --     end
        --     if player2.x >= ball.x then
        --         player2.d2x = -PADDLE_SPEED
        --         if ball.y <= player2.y then
        --             player2.d2y = -PADDLE_SPEED
        --         elseif ball.y >= player2.y then
        --         -- elseif ball.y < player1.y + player1.width then
        --             player2.d2y = PADDLE_SPEED
        --         else
        --         player2.d2y = 0
        --         end
        --     elseif player2.x <= ball.x then
        --         if ball.y >= player2.y - 10 and ball.y <= player2.y + player2.width + 10 then
        --             player2.d2y = -PADDLE_SPEED
        --             player2.d2x = 0
        --         else
        --             player2.d2y = 0
        --             player2.d2x = PADDLE_SPEED
        --         end
        --     else
        --         player2.d2x = 0
        --     end
        -- else
        --     player2.d2x = 0
        --     player2.d2y = 0
        -- end

    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

function love.keypressed(key)
    -- `key` will be whatever key this callback detected as pressed
    if key == 'escape' then
        -- the function LÖVE2D uses to quit the application
        love.event.quit()
    -- if we press enter during either the start or serve phase, it should
    -- transition to the next appropriate state
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- game is simply in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'

            ball:reset()

            -- reset scores to 0
            player1Score = 0
            player2Score = 0

            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 1
            else
                servingPlayer = 2
            end
        end
    end
end

function love.draw()
    push:start()

    love.graphics.clear(40, 45, 52, 255)

    if gameState == 'start' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!",
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    displayScore()

    player1:render()
    player2:render()
    ball:render()

    displayFPS()

    push:finish()
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.setColor(0, 0, 255, 255)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
    love.graphics.setColor(255, 255, 255, 255)

end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(255, 255, 255, 255)
end
