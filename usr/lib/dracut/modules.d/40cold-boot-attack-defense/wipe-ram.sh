#!/bin/sh

## Copyright (C) 2022 - 2022 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Credits:
## First version by @friedy10.
## https://github.com/friedy10/dracut/blob/master/modules.d/40sdmem/wipe.sh

if [ -z "$DRACUT_SYSTEMD" ]; then
    warn_debug() {
        echo "<28>dracut Warning: $*" > /dev/kmsg
        echo "dracut Warning: $*" >&2
    }
    info_debug() {
        echo "<30>dracut Info: $*" > /dev/kmsg
        echo "dracut Info: $*" >&2 || :
    }
else
    warn_debug() {
        echo "Warning: $*" >&2
    }
    info_debug() {
        echo "Info: $*"
    }
fi

ram_wipe() {
   local kernel_wiperam_setting
   ## getarg returns the last parameter only.
   ## if /proc/cmdline contains 'wiperam=skip wiperam=force' the last one wins.
   kernel_wiperam_setting=$(getarg wiperam)

   if [ "$kernel_wiperam_setting" = "skip" ]; then
      info_debug "wipe-ram.sh: Skip, because wiperam=skip kernel parameter detected, OK."
      return 0
   fi

   if [ "$kernel_wiperam_setting" = "force" ]; then
      info_debug "wipe-ram.sh: wiperam=force detected, OK."
   else
      if systemd-detect-virt &>/dev/null ; then
         info_debug "wipe-ram.sh: Skip, because VM detected and not using wiperam=force kernel parameter, OK."
         return 0
      fi
   fi

   info_debug "wipe-ram.sh: Cold boot attack defense... Starting RAM wipe on shutdown..."

   ## TODO: sdmem settings. One pass only. Secure? Configurable?
   sdmem -l -l -v

   info_debug "wipe-ram.sh: RAM wipe completed, OK."

   ## In theory might be better to check this beforehand, but the test is
   ## really fast. The user has no chance of reading the console output
   ## without introducing an artificial delay because the sdmem which runs
   ## after this, results in much more console output.
   info_debug "wipe-ram.sh: Checking if there are still mounted encrypted disks..."

   local dmsetup_actual_output dmsetup_expected_output
   dmsetup_actual_output="$(dmsetup ls --target crypt)"
   dmsetup_expected_output="No devices found"

   if [ "$dmsetup_actual_output" = "$dmsetup_expected_output" ]; then
      info_debug "wipe-ram.sh: Success, there are no more mounted encrypted disks, OK."
   else
      warn_debug "\
wipe-ram.sh: There are still mounted encrypted disks! RAM wipe failed!

debugging information:
dmsetup_expected_output: '$dmsetup_expected_output'
dmsetup_actual_output: '$dmsetup_actual_output'"
   fi

   sleep 3
}

ram_wipe
