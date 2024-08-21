
import ESX from "./esx/main";
import QBCore from "./qb/main"
import Config from "../../config/shared.json"

let Framework: any = null;

if (Config.Framework == 'esx') {
	Framework = ESX
} else if (Config.Framework == 'qb') {
	Framework = QBCore
}

export default Framework
