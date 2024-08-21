type MoneyType = 'bank' | 'cash';

type FrameworkType = {
    getMoney(type:MoneyType):number
}

let Framework: FrameworkType | null = null;

if (GetResourceState('qb-core') == 'started') {
    const QBCore = exports['qb-core'].getSharedObject();

    Framework = {
        getMoney(type:MoneyType) {
            const accounts = QBCore.Functions.GetPlayerData();
            return accounts.money[type] || 0;
        }
    }
} 



export default Framework