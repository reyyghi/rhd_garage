import Framework from "../bridge/framework/init";

RegisterCommand('rm', async (source:number) => {
	const success = Framework.removeMoney(source, 'cash', 500)
	console.log(success)
}, false)