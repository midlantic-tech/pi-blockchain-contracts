const Web3 = require('web3')
attemptConnection('http://127.0.0.1:8545').then(waitForSync).catch(console.log)

function attemptConnection(uri){
    return new Promise((resolve, reject) => {
        const maxConnectionTries = 10
        let attemptNumber = 0
        const connect = () => {
            try {
                attemptNumber += 1
                let web3 = new Web3(new Web3.providers.HttpProvider(uri))
                console.log('Connection to provider successful')
                resolve(web3)
            } catch(err) {
                console.log(err)
                if(attemptNumber < maxConnectionTries) {
                    console.log('Connection to provider failed, retrying...')
                    setTimeout(() => connect(), 2000)
                } else {
                    reject('Could not connect to provider.')
                }
            }
        }
        connect()
    })
}

var firstPass = true
async function waitForSync(web3) {
    let connected = await web3.eth.net.isListenning();
    let sync = await web3.eth.isSyncing();
    let block = await web3.eth.getBlockNumber();
    if (connected && !sync && block > 0) {
        console.log('Done')
    } else {
        if (firstPass) {
            console.log('Waiting for sync to finish...')
            firstPass = false
        }
        setTimeout(() => waitForSync(web3), 2000)
    }
}
