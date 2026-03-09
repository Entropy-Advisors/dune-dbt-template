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
        -- EURC
        ('avalanche_c', 'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'EURC', 'circle',  'token', 'stablecoin', 'euro-pegged', 26857185),
        ('ethereum', 'entropy', 0x1abaea1f7c830bd89acc67ec4af516284b1bc33c, 'EURC',   'circle',  'token', 'stablecoin', 'euro-pegged', 14807227),
        ('base',     'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'EURC',   'circle',  'token', 'stablecoin', 'euro-pegged', 15107859),

        -- wM
        ('arbitrum', 'entropy', 0x46850ad61c2b7d64d08c9c754f45254596696984, 'wM', 'm0', 'token', 'stablecoin', 'usd-pegged', 307758620),
        ('ethereum', 'entropy', 0x6c3ea9036406852006290770bedfcaba0e23a0e8, 'wM', 'm0', 'token', 'stablecoin', 'usd-pegged', 20527882),

        -- PYUSD
        ('arbitrum', 'entropy', 0x46850ad61c2b7d64d08c9c754f45254596696984, 'PYUSD', 'paypal', 'token', 'stablecoin', 'usd-pegged', 333898446),
        ('ethereum', 'entropy', 0x6c3ea9036406852006290770bedfcaba0e23a0e8, 'PYUSD', 'paypal', 'token', 'stablecoin', 'usd-pegged', 15921958),
        
        -- RLUSD
        ('ethereum', 'entropy', 0x8292bb45bf1ee4d140127049757c2e0ff06317ed, 'RLUSD', 'ripple', 'token', 'stablecoin', 'usd-pegged', 20492031),

        -- USDe
        ('ethereum', 'entropy', 0x4c9edd5852cd905f086c759e8383e09bff1e68b3, 'USDe', 'ethena', 'token', 'stablecoin', 'usd-pegged', 18571358),
        ('plasma', 'entropy', 0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34, 'USDe', 'ethena', 'token', 'stablecoin', 'usd-pegged', 570680),
        ('arbitrum', 'entropy', 0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34, 'USDe', 'ethena', 'token', 'stablecoin', 'usd-pegged', 189133001),
        ('base', 'entropy', 0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34, 'USDe', 'ethena', 'token', 'stablecoin', 'usd-pegged', 15768548),

        -- sUSDe
        ('ethereum', 'entropy', 0x9d39a5de30e57443bff2a8307a4256c8797a3497, 'sUSDe', 'ethena', 'token', 'ybs', 'usd-pegged', 18571359),
        ('plasma', 'entropy', 0x211cc4dd073734da055fbf44a2b4667d5e5fe5d2, 'sUSDe', 'ethena', 'token', 'ybs', 'usd-pegged', 574336),
        ('arbitrum', 'entropy', 0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34, 'sUSDe', 'ethena', 'token', 'ybs', 'usd-pegged', 189133410),
        ('base', 'entropy', 0x211cc4dd073734da055fbf44a2b4667d5e5fe5d2, 'sUSDe', 'ethena', 'token', 'ybs', 'usd-pegged', 15768618),

        -- USD1
        ('ethereum', 'entropy', 0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d, 'USD1', 'wlfi', 'token', 'stablecoin', 'usd-pegged', 21720503),
        ('bnb', 'entropy', 0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d, 'USD1', 'wlfi', 'token', 'stablecoin', 'usd-pegged', 46151905),

        -- USDG
        ('ethereum', 'entropy', 0xe343167631d89B6Ffc58B88d6b7fB0228795491D, 'USDG', 'paxos', 'token', 'stablecoin', 'usd-pegged', 20915336),
        ('ink', 'entropy', 0xe343167631d89B6Ffc58B88d6b7fB0228795491D, 'USDG', 'paxos', 'token', 'stablecoin', 'usd-pegged', 11327836),

        -- USDS
        ('ethereum', 'entropy', 0xdc035d45d973e3ec169d2276ddab16f1e407384f, 'USDS', 'sky', 'token', 'stablecoin', 'usd-pegged', 20663730),
        ('arbitrum', 'entropy', 0xdc035d45d973e3ec169d2276ddab16f1e407384f, 'USDS', 'sky', 'token', 'stablecoin', 'usd-pegged', 298070730),
        ('base', 'entropy', 0xdc035d45d973e3ec169d2276ddab16f1e407384f, 'USDS', 'sky', 'token', 'stablecoin', 'usd-pegged', 20884784),

        -- USDai
        ('arbitrum', 'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'USDai',  'usdai', 'token', 'stablecoin', 'usd-pegged', 336209932),
        ('base',     'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'USDai',  'usdai', 'token', 'stablecoin', 'usd-pegged', 38305764),
        ('plasma',   'entropy', 0x0a1a1a107e45b7ced86833863f482bc5f4ed82ef, 'USDai',  'usdai', 'token', 'stablecoin', 'usd-pegged', 700564),

        -- sUSDai
        ('arbitrum', 'entropy', 0x0b2b2b2076d95dda7817e785989fe353fe955ef9, 'sUSDai', 'usdai', 'token', 'ybs', 'usd-pegged', 336209932),
        ('base',     'entropy', 0x0b2b2b2076d95dda7817e785989fe353fe955ef9, 'sUSDai', 'usdai', 'token', 'ybs', 'usd-pegged', 38305764),
        ('plasma',   'entropy', 0x0b2b2b2076d95dda7817e785989fe353fe955ef9, 'sUSDai', 'usdai', 'token', 'ybs', 'usd-pegged', 700564)

        -- RWAs
        -- ('ethereum', 'entropy', 0x8c213ee79581ff4984583c6a801e5263418c4b86, 'JTRSY', 'centrifuge', 'token', 'rwa'),
        -- ('ethereum', 'entropy', 0x5a0f93d040de44e78f251b03c43be9cf317dcf64, 'JAAA',  'centrifuge', 'token', 'rwa'),
        -- ('ethereum', 'entropy', 0x136471a34f6ef19fe571effc1ca711fdb8e49f2b, 'USYC',  'circle',     'token', 'rwa'),
        -- ('ethereum', 'entropy', 0x14d60e7fdc0d71d8611742720e4c50e7a974020c, 'USCC',  'superstate', 'token', 'rwa'),
        -- ('ethereum', 'entropy', 0x43415eb6ff9db7e26a15b704e7a3edce97d31c4e, 'USTB',  'superstate', 'token', 'rwa')
) as t(blockchain, creator, address, name, label, type, category, subcategory, start_block)
