platform_tests_exec = executable('platform-tests', 'tests.c',
  dependencies: [platform_native, check],
  native: true)
test('platform', platform_tests_exec, protocol: 'tap')
