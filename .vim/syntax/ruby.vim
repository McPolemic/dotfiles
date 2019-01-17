autocmd User ProjectionistDetect
\ call projectionist#append(getcwd(),
\ {
\    'app/*.rb': {
\      'alternate': 'test/{}_test.rb'
\    },
\    'test/*_test.rb': {
\      'alternate': 'app/{}.rb'
\    },
\ })
