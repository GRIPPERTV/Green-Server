# Green Server (GS)?
Inspired by Green Threads, Green Server **emulates** a client environment in a server environment, as if `workspace.FilteringEnabled` is disabled. I abandoned this project months ago, but updated it and posted here to see if anyone wants it, it's not perfect so I created a TODO list, but it can already replicate events like Mouse, UserInputService and ContextActionService<br/>

I abandoned this because probably no one would use it, and there are already too many "convert" and the exploit community would probably say that I wasted time creating something that was only used when backdoor was a thing, just wondering...<br/>

### How to use
Just call `require(7830458971)(Player)` in the **first line**, for example:
```lua
require(7830458971)(game.Players.Noob12)
print(game.Players.LocalPlayer.Name) -- Noob12
```
See? When calls `require`, the entire script environment is modified to emulate a client environment<br/>

You don't need to worry if your script uses a old version of GS, because you're calling by the model Id (7830458971). If you don't know, when a ModuleScript named "MainModule" is uploaded, if you call `require` by the uploaded Id, it will call the module and you can use it without needed to import the model<br/>

If you want to edit this project, just click **[here](https://www.roblox.com/library/7830458971)** and import the model in some place

# Fast and lightweight (and not skidded)
Unlike 99% of converters, this one is really good. The only reason I did this project was because the other converters kills server performance over time, for not having good security (handling errors, less use of remotes, script sandbox), plus, not exactly emulates the client environment. The only thing I joke about is skidding, but probably there were people who already skidded some converter and take all the credit from whoever did it, anyway I don't care who skids my project, just a sad person

# Contribution
If you really want to help me with something, please tell me how I can create a Sandbox for the emulated scripts or even make one for me. Basically it's a "monitor" that monitors the emulated scripts, when the player exits or the script is disabled, the emulator disables itself (does not send or receive more values from the Remotes), this can help the server perfomance as hell
