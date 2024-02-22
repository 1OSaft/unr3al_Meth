Config, Locales = {}, {}
----------------------------------------------------------------
Config.Locale = 'en'
Config.checkForUpdates = true
Config.Debug = true
----------------------------------------------------------------

Config.StartProduction = {
    Item = {
        Enabled = true,
        ItemName = 'methlab',
        ConsumeOnStart = false
    },
    Key = {
        Enabled = true,
        StartKey = 'G'
    }
}






Config.Inventory = {
    Type = 'ox_inventory',   --valid options are 'ox_inventory' or 'esx' this used for functions and the way items get added when max weight is reached

    ForceAdd = false, --Should the meth alsways be added, including when the player cant carry it?

    --Only works with ox_inventory
    oxSplit = true, -- if true, the player only receives the amount he can carry
}

Config.Cam = true --Enable the new camera system

Config.Item = {
    Meth = 'meth',
    Acetone = 'acetone',
    Lithium = 'lithium',
    Methlab = 'methlab',

    Chance = { -- At the End a random amount of Meth gets added to the quantity received by questions
        Min = -5,
        Max = 5
    }
}

Config.LogType = 'discord' --Valid options are 'ox_lib', 'discord' or 'disabled'








Config.Police                     = 'police'            -- Your Police society name
Config.PoliceCount                = 0


Config.SmokeColor = 'orange' --orange, white or black



Config.Noti = {
    --Notifications types:
    success = 'success',
    error = 'error',
    info = 'inform',

    --Notification time:
    time = 5000,
}

function notifications(notitype, message, time)
    --Change this trigger for your notification system keeping the variables
    lib.notify({
        title = 'Meth Van',
        description = message,
        type = notitype,
        duration = time
    })
end
