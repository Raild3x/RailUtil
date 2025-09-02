-- Input
-- Stephen Leitnick, Logan Hunt
-- October 10, 2021

--[=[
    @class InputUtil

    Originally written by Stephen Leitnick, this module was forked in order to add some extra functionality.

    The Input package provides access to various user input classes.

    - [PreferredInput](/api/PreferredInput)
    - [Mouse](/api/Mouse)
    - [Keyboard](/api/Keyboard)
    - [Touch](/api/Touch)
    - [Gamepad](/api/Gamepad)

    Reference the desired input modules via the RailUtil .Input index to get started:

    ```lua
    local Input = require(Packages.RailUtil).Input
    local PreferredInput = Input.PreferredInput
    local Mouse = Input.Mouse
    local Keyboard = Input.Keyboard
    local Touch = Input.Touch
    local Gamepad = Input.Gamepad
    ```
]=]

return {
    PreferredInput = require(script.PreferredInput),
    Mouse = require(script.Mouse),
    Keyboard = require(script.Keyboard),
    Touch = require(script.Touch),
    Gamepad = require(script.Gamepad),
}