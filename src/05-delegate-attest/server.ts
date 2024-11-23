/* eslint-disable */
require('dotenv').config()
import express, {Request, Response} from 'express'
import cors from 'cors'
import {
    Attestation,
    EvmChains,
    SignProtocolClient,
    SpMode
} from '@ethsign/sp-sdk'
import {privateKeyToAccount} from 'viem/accounts'

const privateKey = '0x...' // account responsible for paying gas fees
let client: SignProtocolClient
const app = express()

const corsOptions = {
    origin: '*'
}

app.use(cors(corsOptions))

app.use(express.json({limit: '10kb'}))

app.get('/status', (req: Request, res: Response) => {
    res.status(200).json({
        data: {
            message: 'Backend is Operational'
        }
    })
})

app.post(
    '/delegate',
    async (
        req: Request<
            {},
            {},
            {attestation: Attestation; delegationSignature: string}
        >,
        res: Response
    ) => {
        try {
            const {attestation, delegationSignature} = req.body

            const response = await client.createAttestation(attestation, {
                delegationSignature
            })
            res.status(200).json({message: response})
        } catch (error: any) {
            res.status(500).json({
                error: {
                    message: error.message
                }
            })
        }
    }
)

app.all('*', (req: Request, res: Response) => {
    res.status(404).json({
        error: {
            message: `Route: ${req.originalUrl} does not exist on this server`
        }
    })
})

const PORT = process.env.PORT || 8080
app.listen(PORT, async () => {
    client = new SignProtocolClient(SpMode.OnChain, {
        chain: EvmChains.sepolia,
        account: privateKeyToAccount(privateKey) // required in backend environments
    })
    console.log(`🚀Server started Successfully on Port ${PORT}.`)
})
