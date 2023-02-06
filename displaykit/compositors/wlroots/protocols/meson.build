wl = import('unstable_wayland')
wayland_scanner = find_program('wayland-scanner', required: true, native: false)

displaykit_compositor_wlroots_protocols = [
  wl.find_protocol('xdg-shell', state: 'stable')
]

displaykit_compositor_wlroots_protocol_sources = []

foreach protocol : displaykit_compositor_wlroots_protocols
  protocol_name = fs.replace_suffix(fs.name(protocol), '')

  targets = wl.scan_xml(protocol, client: false, server: true, public: true)
  displaykit_compositor_wlroots_protocol_sources += targets[0]
  displaykit_compositor_wlroots_protocol_sources += custom_target('@0@-protocol.h'.format(protocol_name),
    output: '@0@-protocol.h'.format(protocol_name),
    input: protocol,
    command: [wayland_scanner, 'server-header', '@INPUT@', '@OUTPUT@'])
endforeach

displaykit_deps += declare_dependency(sources: displaykit_compositor_wlroots_protocol_sources,
  include_directories: include_directories('.'))
