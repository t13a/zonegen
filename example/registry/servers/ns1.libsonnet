local i = import '../index.libsonnet';
local zonegen = import 'zonegen.libsonnet';

{
  zones: zonegen.overlay(i.zones, zonegen.reverse(i.zones)),
}
