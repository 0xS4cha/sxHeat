fx_version 'cerulean'
game 'gta5'

name 'sxHeat'
description 'Witness reports, suspect descriptions and shrinking search zones for the police, ESX or standalone'
author '0xS4cha'
version '1.0.0'
repository 'https://github.com/0xS4cha/sxHeat'

lua54 'yes'

shared_scripts {
    'core/sh_logger.lua',
    'core/sh_translation.lua',
    'translations/*.lua',
    'core/sh_modules.lua',
    'core/sh_class.lua',
    'core/sh_callback.lua',
    'core/sh_generate.lua',
    'core/sh_utils.lua',
    'shared/config.lua',
}

client_scripts {
    'bridge/cl_bridge.lua',
    'modules/**/cl_*.lua',
    'core/sh_init.lua',
}

server_scripts {
    'bridge/sv_bridge.lua',
    'modules/**/sv_*.lua',
    'core/sh_init.lua',
}

ui_page 'web/dist/index.html'

files {
    'core/SX_HEAT.gfx',
    'web/dist/index.html',
    'web/dist/**/*',
}
