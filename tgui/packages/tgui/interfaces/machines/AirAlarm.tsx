import { round, toFixed } from 'common/math';
import { BooleanLike } from 'common/react';
import { Fragment } from 'inferno';
import { useBackend, useLocalState } from '../../backend';
import { Box, Button, LabeledList, Section, Stack } from '../../components';
import { getGasLabel, getGasColor } from '../../constants';
import { Window } from '../../layouts';
import { AtmosAnalyzerResults, AtmosGasGroupFlags, AtmosGasID, GasContext } from '../common/Atmos';
import { InterfaceLockNoticeBox } from '../common/InterfaceLockNoticeBox';
import { AtmosVentPumpControl, AtmosVentPumpState } from './AtmosVentPump';
import { AtmosVentScrubberControl, AtmosVentScrubberState } from './AtmosVentScrubber';

enum AirAlarmMode {
  Off = 0,
  Scrub = 1,
  Replace = 2,
  Siphon = 3,
  Cycle = 4,
  Panic = 5,
  Contaminated = 6,
  Fill = 7,
}

const AirAlarmModes: [AirAlarmMode, string, string | undefined][] = [
  [AirAlarmMode.Scrub, "Filtering - Maintain area atmospheric integrity", undefined],
  [AirAlarmMode.Contaminated, "Contaminated - Rapidly scrub out contaminants while maintaining atmosphere", undefined],
  [AirAlarmMode.Replace, "Replace - Siphons air while replacement", undefined],
  [AirAlarmMode.Cycle, "Cycle - Siphon air out of the room before replacing.", "danger"],
  [AirAlarmMode.Fill, "Fill - Fill room with air without scrubbing.", undefined],
  [AirAlarmMode.Siphon, "Siphon - Turn off vents and siphon air out of the room", "danger"],
  [AirAlarmMode.Panic, "Panic Siphon - Turns off vents, siphon all air out of the room quickly", "danger"],
];

enum AirAlarmRaise {
  Okay = 0,
  Warning = 1,
  Danger = 2,
}

const AirAlarmRaiseLookup: {
  color: string;
  status: string;
}[] = [
  {
    color: 'good',
    status: 'Okay',
  },
  {
    color: 'average',
    status: 'Warning',
  },
  {
    color: 'bad',
    status: 'Danger',
  },
];

type AirAlarmTLV = [number, number, number, number];

const TLVCheck = (val: number, tlv: AirAlarmTLV | null | undefined) => tlv? (val < tlv[0] || val > tlv[3]
  ? AirAlarmRaise.Danger : val < tlv[1] || val > tlv[2]
    ? AirAlarmRaise.Warning
    : AirAlarmRaise.Okay) : AirAlarmRaise.Okay;

interface ExtendedVentPumpState extends AtmosVentPumpState {
  name: string;
}

interface ExtendedVentScrubberState extends AtmosVentScrubberState {
  name: string;
}

interface AirAlarmData {
  TLV: Record<string, AirAlarmTLV>;
  environment: AtmosAnalyzerResults;
  vents: Record<string, ExtendedVentPumpState>;
  scrubbers: Record<string, ExtendedVentScrubberState>;
  mode: AirAlarmMode;
  gasContext: GasContext;
  // legacy below
  locked: BooleanLike;
  siliconUser: BooleanLike;
  remoteUser: BooleanLike;
  danger_level: number;
  target_temperature: number;
  rcon: number;
  atmos_alarm: BooleanLike;
  fire_alarm: BooleanLike;
  emagged: BooleanLike;
}

export const AirAlarm = (props, context) => {
  const { act, data } = useBackend<AirAlarmData>(context);
  const locked = data.locked && !data.siliconUser && !data.remoteUser;
  const localRaised = AirAlarmRaiseLookup[data.danger_level];
  const pressureRaised = AirAlarmRaiseLookup[TLVCheck(data.environment.pressure, data.TLV['pressure'])];
  const temperatureRaised = AirAlarmRaiseLookup[TLVCheck(data.environment.temperature, data.TLV['temperature'])];
  const temperatureRounded = round(data.environment.temperature, 2);
  return (
    <Window
      width={440}
      height={650}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <InterfaceLockNoticeBox />
          </Stack.Item>
          <Stack.Item>
            <Section title="Environment">
              <LabeledList>
                <LabeledList.Item label="Pressure" color={pressureRaised.color}>
                  {round(data.environment.pressure, 2)} kPa
                </LabeledList.Item>
                <LabeledList.Item label="Temperature" color={temperatureRaised.color}>
                  {temperatureRounded}K ({temperatureRounded - 273.15}°C)
                </LabeledList.Item>
                {
                  Object.entries(data.environment.gases).map(([k, v]) => {
                    const percent = v / data.environment.moles;
                    const gasRaised = AirAlarmRaiseLookup[TLVCheck(v, data.TLV[k])];
                    return (
                      <LabeledList.Item key={k}
                        label={data.environment.names[k] || k} color={gasRaised.color}>
                        {round(percent, 2)}%
                      </LabeledList.Item>
                    );
                  })
                }
                <LabeledList.Item label="Local Status" color={localRaised.color}>
                  {localRaised.status}
                </LabeledList.Item>
                <LabeledList.Item label="Area Status" color={data.atmos_alarm || data.fire_alarm? 'bad' : 'good'}>
                  {data.atmos_alarm? "Atmosphere Alarm" : data.fire_alarm? "Fire Alarm" : "Nominal"}
                </LabeledList.Item>
                {!!data.emagged && (
                  <LabeledList.Item
                    label="Warning"
                    color="bad">
                    Safety measures offline. Device may exhibit abnormal behavior.
                  </LabeledList.Item>
                )}
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
        <AirAlarmUnlockedControl />
        {!locked && (
          <AirAlarmControl />
        )}
      </Window.Content>
    </Window>
  );
};

const AirAlarmUnlockedControl = (props, context) => {
  const { act, data } = useBackend<AirAlarmData>(context);
  const {
    target_temperature,
    rcon,
  } = data;
  return (
    <Section
      title="Comfort Settings">
      <LabeledList>
        <LabeledList.Item label="Remote Control">
          <Button
            selected={rcon === 1}
            content="Off"
            onClick={() => act('rcon', { 'rcon': 1 })} />
          <Button
            selected={rcon === 2}
            content="Auto"
            onClick={() => act('rcon', { 'rcon': 2 })} />
          <Button
            selected={rcon === 3}
            content="On"
            onClick={() => act('rcon', { 'rcon': 3 })} />
        </LabeledList.Item>
        <LabeledList.Item label="Thermostat">
          <Button
            content={target_temperature}
            onClick={() => act('temperature')} />
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const AIR_ALARM_ROUTES = {
  home: {
    title: 'Air Controls',
    component: () => AirAlarmControlHome,
  },
  vents: {
    title: 'Vent Controls',
    component: () => AirAlarmVentScreenWrapped,
  },
  scrubbers: {
    title: 'Scrubber Controls',
    component: () => AirAlarmScrubberScreenWrapped,
  },
  modes: {
    title: 'Operating Mode',
    component: () => AirAlarmModeScreenWrapped,
  },
  thresholds: {
    title: 'Alarm Thresholds',
    component: () => AirAlarmControlThresholds,
  },
};

const AirAlarmControl = (props, context) => {
  const [screen, setScreen] = useLocalState<string>(context, 'screen', 'home');
  const route = AIR_ALARM_ROUTES[screen] || AIR_ALARM_ROUTES.home;
  const Component = route.component();
  return (
    <Section
      title={route.title}
      buttons={screen && (
        <Button
          icon="arrow-left"
          content="Back"
          onClick={() => setScreen('home')} />
      )}>
      <Component />
    </Section>
  );
};


//  Home screen
// --------------------------------------------------------

const AirAlarmControlHome = (props, context) => {
  const { act, data } = useBackend<AirAlarmData>(context);
  const [screen, setScreen] = useLocalState<string>(context, 'screen', '');
  const {
    mode,
    atmos_alarm,
  } = data;
  return (
    <>
      <Button
        icon={atmos_alarm
          ? 'exclamation-triangle'
          : 'exclamation'}
        color={atmos_alarm && 'caution'}
        content="Area Atmosphere Alarm"
        onClick={() => act(atmos_alarm ? 'reset' : 'alarm')} />
      <Box mt={1} />
      <Button
        icon={mode === 3
          ? 'exclamation-triangle'
          : 'exclamation'}
        color={mode === 3 && 'danger'}
        content="Panic Siphon"
        onClick={() => act('mode', {
          mode: mode === 3 ? 1 : 3,
        })} />
      <Box mt={2} />
      <Button
        icon="sign-out-alt"
        content="Vent Controls"
        onClick={() => setScreen('vents')} />
      <Box mt={1} />
      <Button
        icon="filter"
        content="Scrubber Controls"
        onClick={() => setScreen('scrubbers')} />
      <Box mt={1} />
      <Button
        icon="cog"
        content="Operating Mode"
        onClick={() => setScreen('modes')} />
      <Box mt={1} />
      <Button
        icon="chart-bar"
        content="Alarm Thresholds"
        onClick={() => setScreen('thresholds')} />
    </>
  );
};

//* Vents *//

const AirAlarmVentScreenWrapped = (props, context) => {
  const { data, act } = useBackend<AirAlarmData>(context);
  return (
    <AirAlarmVentScreen
      vents={data.vents}
      dirToggle={(id) => act('vent', { id: id, command: 'direction' })}
      powerToggle={(id) => act('vent', { id: id, command: 'power' })}
      internalToggle={(id) => act('vent', { id: id, command: 'internalToggle' })}
      internalSet={(id, amt) => act('vent', { id: id, command: 'internalPressure', target: amt })}
      externalToggle={(id) => act('vent', { id: id, command: 'externalToggle' })}
      externalSet={(id, amt) => act('vent', { id: id, command: 'externalPressure', target: amt })} />
  );
};

interface AirAlarmVentScreenProps {
  powerToggle: (id: string, on?: boolean) => void;
  internalToggle: (id: string, on?: boolean) => void;
  externalToggle: (id: string, on?: boolean) => void;
  internalSet: (id: string, kpa: number | 'default') => void;
  externalSet: (id: string, kpa: number | 'default') => void;
  dirToggle: (id: string, siphon?: boolean) => void;
  vents: Record<string, ExtendedVentPumpState>;
}

const AirAlarmVentScreen = (props: AirAlarmVentScreenProps) => {
  return (
    <Stack vertical>
      {Object.entries(props.vents).map(([idTag, vent]) => (
        <Stack.Item key={idTag}>
          <AtmosVentPumpControl
            state={vent}
            title={vent.name}
            powerToggle={(on) => props.powerToggle(idTag, on)}
            dirToggle={(siphon) => props.dirToggle(idTag, siphon)}
            internalSet={(val) => props.internalSet(idTag, val)}
            externalSet={(val) => props.externalSet(idTag, val)}
            internalToggle={(on) => props.internalToggle(idTag, on)}
            externalToggle={(on) => props.externalToggle(idTag, on)} />
        </Stack.Item>
      ))}
    </Stack>
  );
};

//* Scrubbers *//

const AirAlarmScrubberScreenWrapped = (props, context) => {
  const { data, act } = useBackend<AirAlarmData>(context);
  return (
    <AirAlarmScrubberScreen
      gasContext={data.gasContext}
      scrubbers={data.scrubbers}
      powerToggle={(id) => act('scrubber', { id: id, command: 'power' })}
      siphonToggle={(id) => act('scrubber', { id: id, command: 'siphon' })}
      expandToggle={(id) => act('scrubber', { id: id, command: 'highPower' })}
      gasToggle={(id, gas) => act('scrubber', { id: id, command: 'gasID', target: gas })}
      groupToggle={(id, flags) => act('scrubber', { id: id, command: 'gasGroup', target: flags })} />
  );
};

interface AirAlarmScrubberScreenProps {
  powerToggle: (id: string, on?: boolean) => void;
  siphonToggle: (id: string, on?: boolean) => void;
  expandToggle: (id: string, on?: boolean) => void;
  gasToggle: (id: string, gas: AtmosGasID, on?: boolean) => void;
  groupToggle: (id: string, group: AtmosGasGroupFlags, on?: boolean) => void;
  scrubbers: Record<string, ExtendedVentScrubberState>;
  gasContext: GasContext;
}

const AirAlarmScrubberScreen = (props: AirAlarmScrubberScreenProps) => {
  return (
    <Stack vertical>
      {Object.entries(props.scrubbers).map(([idTag, scrubber]) => (
        <Stack.Item key={idTag}>
          <AtmosVentScrubberControl
            state={scrubber}
            context={props.gasContext}
            title={scrubber.name}
            powerToggle={(on) => props.powerToggle(idTag, on)}
            siphonToggle={(on) => props.siphonToggle(idTag, on)}
            expandToggle={(on) => props.expandToggle(idTag, on)}
            idToggle={(id, on) => props.gasToggle(idTag, id, on)}
            groupToggle={(group, on) => props.groupToggle(idTag, group, on)} />
        </Stack.Item>
      ))}
    </Stack>
  );
};

//* Modes *//

// todo: legacy, remove
const AirAlarmModeScreenWrapped = (props, context) => {
  const { data, act } = useBackend<AirAlarmData>(context);
  return (
    <AirAlarmModeScreen
      selected={data.mode}
      setAct={(mode) => act('mode', { mode: mode })} />
  );
};

interface AirAlarmModeScreenProps {
  selected: AirAlarmMode;
  setAct: (AirAlarmMode) => void;
}

const AirAlarmModeScreen = (props: AirAlarmModeScreenProps) => {
  return (
    <Stack vertical>
      {AirAlarmModes.map(([mode, desc, color]) => (
        <AirAlarmModeButton
          key={mode}
          desc={desc}
          color={color}
          selected={props.selected === mode}
          setAct={() => props.setAct(mode)} />
      ))}
    </Stack>
  );
};

interface AirAlarmModeButtonProps {
  desc: string;
  selected: boolean;
  setAct?: () => void;
  color?: string;
}

const AirAlarmModeButton = (props: AirAlarmModeButtonProps) => {
  return (
    <Button
      icon={props.selected? 'check-square-o' : 'square-o'}
      content={props.desc}
      onClick={() => props.setAct?.()}
      selected={props.selected}
      color={props.selected && props.color} />
  );
};


//  Thresholds
// --------------------------------------------------------

const AirAlarmControlThresholds = (props, context) => {
  const { act, data } = useBackend<AirAlarmData>(context);
  const { thresholds } = data;
  return (
    <table
      className="LabeledList"
      style={{ width: '100%' }}>
      <thead>
        <tr>
          <td />
          <td className="color-bad">min2</td>
          <td className="color-average">min1</td>
          <td className="color-average">max1</td>
          <td className="color-bad">max2</td>
        </tr>
      </thead>
      <tbody>
        {thresholds.map(threshold => (
          <tr key={threshold.name}>
            <td className="LabeledList__label">
              <span className={"color-" + getGasColor(threshold.name)}>
                {getGasLabel(threshold.name)}
              </span>
            </td>
            {threshold.settings.map(setting => (
              <td key={setting.val}>
                <Button
                  content={toFixed(setting.selected, 2)}
                  onClick={() => act('threshold', {
                    env: setting.env,
                    var: setting.val,
                  })} />
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
};
