import _Bar from './widgets/bar';
import OSD from './widgets/osd';
import { forMonitors } from './lib/utils';

App.config({
  windows: [
    ...forMonitors(OSD),
  ],
})
