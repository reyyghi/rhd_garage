import Framework from "../bridge/framework/init";

const Delay = (time: number) => new Promise(resolve => setTimeout(resolve, time));

RegisterCommand("sv",async (source:number, args: string[], rawCommand:string) => {
	const [model] = args
	const modelHash = GetHashKey(model)

	if (!IsModelAVehicle(modelHash)) return
	RequestModel(modelHash)
	while (!HasModelLoaded) await Delay(100)

	const [x,y,z] = GetEntityCoords(PlayerPedId(), true)
	const h = GetEntityHeading(PlayerPedId())
	const veh = CreateVehicle(modelHash,x,y,z,h, true, true)

	while (!DoesEntityExist(veh)) await Delay(100)

	SetPedIntoVehicle(PlayerPedId(), veh, -1)
}, false)

RegisterCommand('testdata', async () => {
	const name = Framework.getName()
	const cash = Framework.getMoney('cash')
	const bank = Framework.getMoney('bank')
	console.log(name, cash, bank)
}, false)