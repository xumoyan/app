const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60;

const default_ss58_prefix = {
  'info': 'default',
  'text': 'Default for the connected node',
  'value': 42,
};
const prefixList = [
  default_ss58_prefix,
  {'info': 'substrate', 'text': 'Substrate (development)', 'value': 42},
  {'info': 'kusama', 'text': 'Kusama (canary)', 'value': 2},
  {'info': 'polkadot', 'text': 'Polkadot (live)', 'value': 0}
];

/// use this storage to display un-finalized tx
const local_tx_store_key = 'local_tx_store';

/// app versions
enum BuildTargets { apk, playStore, dev }
const String app_beta_version = 'v2.3.9-beta.2';
const int app_beta_version_code = 2392;

/// para-chains
const relay_chain_name_ksm = 'kusama';
const relay_chain_name_dot = 'polkadot';
const para_chain_name_statemine = 'statemine';
const para_chain_name_statemint = 'statemint';
const para_chain_name_karura = 'karura';
const para_chain_name_acala = 'acala';
const para_chain_name_bifrost = 'bifrost';
const chain_name_chainx = 'chainx';
const chain_name_edgeware = 'edgeware';
const chain_name_dbc = 'dbc';
const chain_name_robonomics = 'Robonomics';
const plugin_github_links = {
  relay_chain_name_ksm: 'https://github.com/polkawallet-io/app/issues',
  relay_chain_name_dot: 'https://github.com/polkawallet-io/app/issues',
};
const plugin_from_community = [
  chain_name_chainx,
  chain_name_edgeware,
  para_chain_name_bifrost,
  chain_name_dbc,
  chain_name_robonomics
];

const xcm_base_weight = 1000000000;
const xcm_dest_weight_ksm = 3 * xcm_base_weight;
const xcm_dest_weight_bifrost = 600000000;

const xcm_send_fees = {
  relay_chain_name_ksm: {
    'fee': '106666660',
    'existentialDeposit': '333333333',
  },
  para_chain_name_statemine: {
    'fee': '4000000000',
    'existentialDeposit': '33333333',
  },
  para_chain_name_karura: {
    'fee': '160000000',
    'existentialDeposit': '100000000',
  },
  para_chain_name_acala: {
    'fee': '0',
    'existentialDeposit': '10000000000',
  },
  para_chain_name_bifrost: {
    'fee': '4800000000',
    'existentialDeposit': '100000000',
  },
};

const xcm_support_dest_chains = {
  relay_chain_name_ksm: [
    relay_chain_name_ksm,
    para_chain_name_statemine,
    para_chain_name_karura,
  ],
  // todo: KSM from statemine to kusasma has bug
  // para_chain_name_statemine: [
  //   para_chain_name_statemine,
  //   relay_chain_name_ksm,
  // ],
  // todo: transfer KAR to bifrost is not open yet
  // para_chain_name_karura: [
  //   para_chain_name_karura,
  //   para_chain_name_bifrost,
  // ],
};

const bridge_account = {
  'mandala': '5G9VH1qNxbPE39SW9SWmDDhePxt1zxLScJ7ync57MFhJSh1v',
  'acala': '13YMK2eYoAvStnzReuxBjMrAvPXmmdsURwZvc62PrdXimbNy'
};

const show_guide_status_key = 'show_guide_status';

const JPUSH_APP_KEY = 'dfa60080aa05c5c7b7dc7aa0';
