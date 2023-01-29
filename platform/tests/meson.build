foreach name : [ 'platform' ]
  platform_tests_exec = executable('test-@0@'.format(name), 'test-@0@.c'.format(name),
    dependencies: [platform_native, check],
    native: true)
  test(name, platform_tests_exec, protocol: 'tap', suite: ['platform'])
endforeach
