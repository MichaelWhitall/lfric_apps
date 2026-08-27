import sys

from metomi.rose.upgrade import MacroUpgrade  # noqa: F401

from .version31_32 import *


class UpgradeError(Exception):
    """Exception created when an upgrade fails."""

    def __init__(self, msg):
        self.msg = msg

    def __repr__(self):
        sys.tracebacklimit = 0
        return self.msg

    __str__ = __repr__


"""
Copy this template and complete to add your macro

class vnXX_txxx(MacroUpgrade):
    # Upgrade macro for <TICKET> by <Author>

    BEFORE_TAG = "vnX.X"
    AFTER_TAG = "vnX.X_txxx"

    def upgrade(self, config, meta_config=None):
        # Add settings
        return config, self.reports
"""

class vn32_t717(MacroUpgrade):
    # Upgrade macro for PR#717 by Mike Whitall

    BEFORE_TAG = "vn3.2"
    AFTER_TAG = "vn3.2_t717"

    def upgrade(self, config, meta_config=None):
        # Add settings

        # Add new comorph namelist
        # Append after 'convection' in configuration.nml
        source = self.get_setting_value(
            config, ["file:configuration.nml", "source"]
        )
        source = re.sub(
            r'(= )(\(?)namelist:convection(\)?)(\n)',
            r'\1\2namelist:convection\3\4\1\2namelist:comorph\3\4',
            source,
        )
        self.change_setting_value(
            config, ["file:configuration.nml", "source"], source
        )

        # Move existing comorph namelist entries from the "convection"
        # namelist to the new "comorph" namelist.
        nml1 = "namelist:convection"
        nml2 = "namelist:comorph"
        for entry in ["par_gen_mass_fac", "par_gen_rhpert",
                      "par_radius_ppn_max", "resdep_precipramp", "dx_ref"]:
            source = self.get_setting_value(config, [nml1, entry])
            self.remove_setting(config, [nml1, entry])
            self.add_setting(config, [nml2, entry], source)

        return config, self.reports
