--- ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗███╗   ███╗███████╗███╗   ██╗████████╗
--- ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
--- ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
--- ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
--- ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
--- ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
---@field UseBuildInCompanyBalance boolean: If you dont want to use the balance built into the Management Menu, set this to false and configure config.server.lua to be compatible with your server, for example a script for banks that may have company accounts
Config.UseBuildInCompanyBalance = true
Config.RemoveBalanceFromMenu = false -- if you are using other than our prepared esx_society or buildet-in balance, set it true

Config.ESXSocietyEvents = {
    ['check'] = 'esx_society:checkSocietyBalance',
    ['withdraw'] = 'esx_society:withdrawMoney',
    ['deposit'] = 'esx_society:depositMoney',
}

---@field BillMoneyToSocietyPercent number: Do you want the company to receive a % from paid billing of tuning a vehicle?
Config.BillMoneyToSocietyPercent = 80

---@field BillMoneyToSellerPercent number: Do you want the tuner to receive a % from paid billing of tuning a vehicle?
Config.BillMoneyToSellerPercent = 20

Config.RequiredJobToBeHired = 'unemployed'



--- ██╗   ██╗███╗   ███╗███████╗     ██████╗██╗████████╗██╗   ██╗██╗  ██╗ █████╗ ██╗     ██╗     
--- ██║   ██║████╗ ████║██╔════╝    ██╔════╝██║╚══██╔══╝╚██╗ ██╔╝██║  ██║██╔══██╗██║     ██║     
--- ██║   ██║██╔████╔██║███████╗    ██║     ██║   ██║    ╚████╔╝ ███████║███████║██║     ██║     
--- ╚██╗ ██╔╝██║╚██╔╝██║╚════██║    ██║     ██║   ██║     ╚██╔╝  ██╔══██║██╔══██║██║     ██║     
---  ╚████╔╝ ██║ ╚═╝ ██║███████║    ╚██████╗██║   ██║      ██║   ██║  ██║██║  ██║███████╗███████╗
---   ╚═══╝  ╚═╝     ╚═╝╚══════╝     ╚═════╝╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝
Config.VMSCityHallResource = 'vms_cityhall'
Config.UseVMSCityHall = GetResourceState(Config.VMSCityHallResource) == 'started'

---@field UseCityHallResumes boolean: If you are using vms_cityhall and using the job center section and want players to send resumes to companies, set true
Config.UseCityHallResumes = true

---@field UseCityHallTaxes boolean: If you are using vms_cityhall and you use the tax option and want companies to have to pay tax on the money they earn, set true
Config.UseCityHallTaxes = true

---@field UseCityHallIncludedTaxes boolean: If you use taxes, do you want the taxes to be included in the default amounts you configure in vms_gym, or do you want them to be price + tax paid by the customer
Config.UseCityHallIncludedTaxes = false