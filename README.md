# PUCRS code for the MAPC of 2016

To run our code first download the latest release, extract it to a folder, and import that folder to Eclipse.
If you wish to run the server, the monitor, and our code all with one click, just right-click test/pucrs.agentcontest2016/ScenarioRunServer.java file, "Run as", "jUnit Test".

If you prefer to run the server and the monitor separately, do so and then right-click test/pucrs.agentcontest2016/ScenarioConnectToServer.java file, "Run as", "jUnit Test".

List of major known bugs:
* Agents are calling service breakdown more than necessary (we had to force it otherwise they could enter a loop going between two charging stations)
* Automatic map/round change is not working, we believe it is something to do with our threads trying to access osm files while they are still in use

I am sure there are many more undocumented bugs, if you find them let us know :)

We also never optimised the code. We planned on eventually doing so before the contest, but we had more pressing bugs to solve.
We leave that to you if you wish (or check back here in the next contest, in 2017).
