{{
    config(
        alias = 'dim_labels',
        materialized = 'view'
    )
}}

select
    *
from (
    values
        -- USDai
        ('arbitrum', 'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'USDai',  'usdai', 'token', 'stablecoin', 336209932, timestamp '2024-05-01 00:00:00'),
        ('base',     'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'USDai',  'usdai', 'token', 'stablecoin', 38305764,  timestamp '2024-03-01 00:00:00'),
        ('plasma',   'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'USDai',  'usdai', 'token', 'stablecoin', 700564,    timestamp '2024-10-01 00:00:00'),

        -- sUSDai
        ('arbitrum', 'entropy', 0x0b2b2b2076d95dda7817e785989fe353fe955ef9, 'sUSDai', 'usdai', 'token', 'ybs', 336209932, timestamp '2024-05-01 00:00:00'),
        ('base',     'entropy', 0x0b2b2b2076d95dda7817e785989fe353fe955ef9, 'sUSDai', 'usdai', 'token', 'ybs', 38305764,  timestamp '2024-03-01 00:00:00'),
        ('plasma',   'entropy', 0x0b2b2b2076d95dda7817e785989fe353fe955ef9, 'sUSDai', 'usdai', 'token', 'ybs', 700564,    timestamp '2024-10-01 00:00:00')

        -- RWAs
        -- ('ethereum', 'entropy', 0x8c213ee79581ff4984583c6a801e5263418c4b86, 'JTRSY', 'centrifuge', 'token', 'rwa', <min_block_number>, <min_block_time>),
        -- ('ethereum', 'entropy', 0x5a0f93d040de44e78f251b03c43be9cf317dcf64, 'JAAA',  'centrifuge', 'token', 'rwa', <min_block_number>, <min_block_time>),
        -- ('ethereum', 'entropy', 0x136471a34f6ef19fe571effc1ca711fdb8e49f2b, 'USYC',  'circle',     'token', 'rwa', <min_block_number>, <min_block_time>),
        -- ('ethereum', 'entropy', 0x14d60e7fdc0d71d8611742720e4c50e7a974020c, 'USCC',  'superstate', 'token', 'rwa', <min_block_number>, <min_block_time>),
        -- ('ethereum', 'entropy', 0x43415eb6ff9db7e26a15b704e7a3edce97d31c4e, 'USTB',  'superstate', 'token', 'rwa', <min_block_number>, <min_block_time>)

) as t(blockchain, creator, address, name, label, type, category, min_block_number, min_block_time)
