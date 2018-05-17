function love.conf(t)
    t.modules.joystick = true
    t.modules.physics = false
    t.window.resizable = true
    t.window.height = 224*3
    t.window.width = 360*3
    t.window.vsync = true

    t.version = "11.1"
    t.identity = "CATcher"
    t.window.title = "CATcher"
end
