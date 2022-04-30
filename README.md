## Green Server (GS)
Inspired by Green Threads, Green Server emulates a client environment in a server environment, as if `workspace.FilteringEnabled` is disabled. I abandoned this project months ago, but updated it and posted here to see if anyone wants it, it's not perfect so I created a TODO list, but it can already replicate events like Mouse, UserInputService and ContextActionService<br/>

### How to use
Just call `require(7830458971)(Player)` in the **first line**, for example:
```lua
require(7830458971)(game.Players.Noob12)
print(game.Players.LocalPlayer.Name) -- Noob12
```
When calls `require`, the entire script environment is modified to emulate a client environment<br/>

To edit this project, just click **[here](https://www.roblox.com/library/7830458971)** and import the model in some place
