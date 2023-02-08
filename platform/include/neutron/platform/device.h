#pragma once

#include <neutron/elemental.h>
#include <stdbool.h>
#include <stdint.h>

/**
 * SECTION: device
 * @section_id: device
 * @title: Device
 * @short_description: A hardware device
 */

/**
 * NtDeviceKind:
 * @NT_DEVICE_MISC: Miscellaneous devices
 * @NT_DEVICE_HID: Human interface devices
 * @NT_DEVICE_DISPLAY: Display devices
 * @NT_DEVICE_AUDIO: Audio devices
 * @NT_DEVICE_NET: Networking devices
 * @NT_DEVICE_STORAGE: Storage devices
 * @NT_DEVICE_PLATFORM: Platform devices
 *
 * Enum of different kinds of devices.
 */
typedef enum _NtDeviceKind {
  NT_DEVICE_MISC = 0,
  NT_DEVICE_HID,
  NT_DEVICE_DISPLAY,
  NT_DEVICE_AUDIO,
  NT_DEVICE_NET,
  NT_DEVICE_STORAGE,
  NT_DEVICE_PLATFORM
} NtDeviceKind;

/**
 * NtDeviceBus:
 * @NT_DEVICE_BUS_NONE: No bus
 * @NT_DEVICE_BUS_PCI: PCI bus
 * @NT_DEVICE_BUS_USB: USB bus
 * @NT_DEVICE_BUS_AGP: AGP bus
 * @NT_DEVICE_BUS_PCIE: PCI-e bus
 * @NT_DEVICE_BUS_SATA: SATA bus
 * @NT_DEVICE_BUS_IDE: IDE bus
 * @NT_DEVICE_BUS_SCSI: SCSI bus
 * @NT_DEVICE_BUS_IEEE1394: IEEE 1394 (aka. FireWire) bus
 * @NT_DEVICE_BUS_THUNDERBOLT: Thunderbolt bus
 * @NT_DEVICE_BUS_NVME: NVMe bus
 * @NT_DEVICE_BUS_SAS: SAS bus
 *
 * Enum of different device buses.
 */
typedef enum _NtDeviceBus {
  NT_DEVICE_BUS_NONE = 0,
  NT_DEVICE_BUS_PCI,
  NT_DEVICE_BUS_USB,
  NT_DEVICE_BUS_AGP,
  NT_DEVICE_BUS_PCIE,
  NT_DEVICE_BUS_SATA,
  NT_DEVICE_BUS_IDE,
  NT_DEVICE_BUS_SCSI,
  NT_DEVICE_BUS_IEEE1394,
  NT_DEVICE_BUS_THUNDERBOLT,
  NT_DEVICE_BUS_NVME,
  NT_DEVICE_BUS_SAS
} NtDeviceBus;

/**
 * NtDeviceQuery:
 * @kind: The kind of device
 * @bus: The bus for the device
 * @virt: Boolean value to look for virtual devices
 * @phys: Boolean value to look for physical devices
 * @parameters: Querying parameters
 *
 * Querying information for a device
 */
typedef struct _NtDeviceQuery {
  NtDeviceKind kind;
  NtDeviceBus bus;

  bool virt;
  bool phys;

  NtTypeArgument* parameters;
} NtDeviceQuery;

/**
 * NtDevice:
 * @instance: An %NtTypeInstance associated with this
 * @get_query: Method for getting the query information
 *
 * A hardware device
 */
typedef struct _NtDevice {
  NtTypeInstance instance;
  NtDeviceQuery (*get_query)(struct _NtDevice* self);
} NtDevice;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DEVICE:
 *
 * The %NtType ID of %NtDevice
 */
#define NT_TYPE_DEVICE nt_device_get_type()
NT_DECLARE_TYPE(NT, DEVICE, NtDevice, nt_device);

/**
 * nt_device_get_query:
 * @self: Instance of %NtDevice
 *
 * Gets the querying information for a device.
 *
 * Returns: A device query
 */
NtDeviceQuery nt_device_get_query(NtDevice* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
