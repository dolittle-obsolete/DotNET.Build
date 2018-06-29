#load "Globals.fsx"
#load "ProcessHelpers.fsx"

open Fake
open Globals
open ProcessHelpers

Target "UpdateVersionOnBuildServer" (fun _ ->
    if( Globals.IsAppVeyor ) then
        tracef "Updating build version for AppVeyor to %s-%s\n" (Globals.BuildVersion.AsString(), Globals.BuildNumber.AsString())
        let allArgs = sprintf "UpdateBuild -Version \"%s-%s\"" (Globals.BuildVersion.AsString(), Globals.BuildNumber.AsString())
        ProcessHelpers.Spawn("appveyor", allArgs) |> ignore
)