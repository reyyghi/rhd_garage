type MoneyType = 'bank' | 'cash';

type FrameworkClientType = {
    getName(): string;
    checkJob(name: string, grade?: number): boolean;
    getMoney(type: MoneyType): number;
    playerLoaded():boolean;
}

type FrameworkServerType = {
    getIdentifier(source: number, type:string): string|boolean;
    removeMoney(source:number, type:string, count:number):boolean;
}

interface EsXJobs {
    name:string,
    label:string,
    grade:number,
    grade_label:string
}

interface PlayerData {
    name:string;
    job: EsXJobs,
    accounts: {
        name:string;
        money:number
    }[];
}


type FrameworkType = FrameworkClientType | FrameworkServerType;

let PlayerLoaded = false;
let Framework: FrameworkType | null = null;

if (GetResourceState('es_extended') === 'started') {
    const ESX = exports.es_extended.getSharedObject();
    const IsServer = IsDuplicityVersion();

    if (!IsServer) {

        let playerMoney = {
            cash: 0,
            bank: 0
        }

        let playerJob = {
            name: 'nganggur',
            label: 'Pengangguran',
            grade: {
                level: 0,
                label: 'Nganggur Su'
            }
        }

        let playerName = 'Boren Anjay'

        function registerCache(playerData:PlayerData) {
            const accounts = playerData.accounts

            playerJob.name = playerData.job.name
            playerJob.label = playerData.job.label
            playerJob.grade.level = playerData.job.grade
            playerJob.grade.label = playerData.job.grade_label

            for (let index = 0; index < accounts.length; index++) {
                const data = accounts[index];
                if (data.name === 'bank') {
                    playerMoney.bank = data.money;
                } else if (data.name === 'money') {
                    playerMoney.cash = data.money;
                }
            }

            playerName = playerData.name;
            PlayerLoaded = true;
        }

        onNet('esx:playerLoaded', function (playerData:PlayerData) {
            registerCache(playerData);
        })

        onNet('esx:setAccountMoney', function (account: { name: string; money: number }) {
            if (typeof account !== 'object') return;
            if (account.name == 'money') {
                playerMoney.cash = account.money
            } else if (account.name == 'bank') {
                playerMoney.bank = account.money
            }
        })

        onNet('esx:setJob', function (Job: EsXJobs) {
            if (typeof Job !== 'object') return;
            playerJob.name = Job.name
            playerJob.label = Job.label
            playerJob.grade.level = Job.grade
            playerJob.grade.label = Job.grade_label
        })

        on('onResourceStart', function (resource:string) {
            if (resource == GetCurrentResourceName()) {
                const pData = ESX.GetPlayerData();
                registerCache(pData);
            }
        })

        Framework = {
            playerLoaded():boolean {
                return PlayerLoaded;
            },

            getMoney(type: MoneyType): number {
                return playerMoney[type];
            },

            getName(): string {
                return playerName;
            },

            checkJob(name: string, grade?: number): boolean {
                if (playerJob.name === name) {
                    if (grade !== undefined) {
                        return typeof grade === 'number' && playerJob.grade.level >= grade;
                    }
                    return true;
                }
                return false;
            }
        };
    } else {
        Framework = {
            
            getIdentifier(source: number, type:string): string|boolean {
                const player = ESX.GetPlayerFromId(source);
                return player ? player.identifier : false;
            },

            removeMoney(source:number, type:string, count:number):boolean {
                let results = false;
                const player = ESX.GetPlayerFromId(source);

                if (player) {
                    const mType = type == 'cash' && 'money' || type
                    const pMoney = player.getAccount(mType).money

                    if (pMoney >= count) {
                        results = true;
                        player.removeAccountMoney(mType, count, '');
                    }
                }

                return results;
            }
        };
    }
}

export default Framework;
