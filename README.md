# power_rates

Any available data here is mapped to UTC time in order to disregard potential errors due to misconfigured TZ's.

## SCE

NEM3 Export rates come from SCE's `SCE_2024_NBT_EEC_MIDAS_Upload.csv` file.
I don't believe this contains the "adder" values.

## Using data here in Home Assistant

(Experimental, not sure how often HA refreshes this data)
```
sensor:
- platform: rest
  unique_id: sce_tou_d_nbt24_export
  name: SCE TOU-D-NBT24 Export Rates
  unit_of_measurement: USD/kWh
  resource_template: https://raw.githubusercontent.com/xaemiphor/power_rates/refs/heads/main/sce/NBT24.export/{{ utcnow().strftime('%Y/%m/%d/%H') }}
  value_template: "{{ (value | float) + (0.04 | float) }}"
```
NBT23/NBT24 is the "rate lock-in" year, NBT00 is the non-locked in version?

I'm finding these values inconsistent from Enphase's app, so I'm unsure which is right yet.

`utcnow()` is used as all data here is stored in UTC.
