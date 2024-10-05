import Bar from './widgets/bar';
import OSD from './widgets/osd';
import { forMonitors } from './lib/utils';

App.config({
  style: "./style.css",
  windows: [
    ...forMonitors(Bar),
    ...forMonitors(OSD),
  ],
})
