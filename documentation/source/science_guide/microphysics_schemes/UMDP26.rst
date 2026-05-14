====================================================
The Large-Scale Precipitation Parametrization Scheme
====================================================

:Author: R. Forbes, J. Wilkinson, D. Wilson, I. Boutle, S. A. Smith,
         V. Varma\ :math:`^{1}`

.. role:: raw-latex(raw)
   :format: latex
..

Introduction
============

This document describes the science of the version 3 large-scale
precipitation schemes at version 13.2 of the UM.

The next section introduces the basic microphysical structure of the
schemes and the second section the variables that are used within the
scheme. The next two sections look at the parametrization of atmospheric
quantities and hydrometeor characteristics. The sub grid-scale treatment
is introduced next and then details of the parametrization of each of
the transfer processes outlined in the first section. The final section
deals with numerical implementation of the processes within the model.
We have included references to the origins of terms and parametrizations
where they are known. Many of the representations come from work by
Damian Wilson in developing the scheme and are unpublished. We note
these when they arise. The source for a couple of parametrizations is
unknown; these are noted where they arise. However, current work aims to
remove as many of these unknowns in favour of relations with a
scientific and credibility basis.

The purpose of the large-scale precipitation scheme (often referred to
as the ‘microphysics’ scheme) is to model the significant atmospheric
microphysical processes that result in the downwards transfer of water
in the atmosphere (precipitation) and phase changes between vapour,
liquid water and ice water. The model carries variables that represent
water vapour, liquid water droplets, rain and three types of ice (a
large-ice mode or ‘aggregates’, a small-ice mode or ‘crystals’ and
graupel), although not all of these are used operationally. Within each
model gridbox the large-scale precipitation scheme will calculate the
transfers of moisture between each of these categories, by modelling the
microphysical processes that occur in the atmosphere. The scheme will
also advect the ice and rain categories to represent their fall through
the atmosphere. This will result in transport of water downwards and the
possibility of precipitation at the surface. Hence the large-scale
precipitation scheme works on model columns, starting at the top and
moving downwards.

.. _`sec:terms`:

A note on terminology
---------------------

In the UM, all quantities are described as the ratio of the mass of a
water species (vapour, rain, ice crystals, ice aggregates or graupel) to
the unit mass of dry air. However, the term ’specific humidity’ is
applied generally to water vapour only and is defined as the mass of
water vapour per the total mass (air plus vapour). In practice, the two
have approximately the same value, as the mass of vapour is much less
than the mass of air. :umdp:‘015‘ (Dynamics) shows that all quantities
are passed into model physics as ’mixing ratios’; therefore we have used
this term in this document. However, in the code you may see references
to specific humidity. These are technically incorrect and they should
read mixing ratio, but the difference is only of academic interest.

Microphysical processes
-----------------------

The scheme is originally based upon that developed by
:raw-latex:`\cite{Rutledge:Hobbs:1983}` and was developed principally by
Sue Ballard and then Damian Wilson. The earlier, 3B scheme is described,
along with sample results, in :raw-latex:`\cite{Wilson:Ballard:1999}`.
This scheme has been retired as of VN7.7 of the UM.

Only four phases are assumed (liquid, vapour, ice aggregates and rain)
and the microphysical processes represented are:

- Fall of ice and rain under gravity

- Primary nucleation of ice particles by heterogeneous and homogeneous
  nucleation

- Deposition and sublimation of ice

- Aggregation: The collection of ice particles by other ice particles

- Riming: Ice particles collecting cloud droplets, which freeze on
  impact

- Capture of raindrops by falling ice particles, which increases the ice
  content

- Melting of ice particles

- Evaporation of rain

- Accretion: The collection of cloud droplets by raindrops

- Autoconversion: The production of rain and drizzle by converting cloud
  water into rain

Note that the condensation and evaporation of cloud droplets are
implemented as part of the large-scale cloud scheme. For further
details, please refer to :umdp:‘029‘.

There are many cloud microphysics processes which are not represented in
this parametrization. They are *assumed* to be of less significance than
the processes that are represented and their omission allows a
reasonable representation of clouds to be made without excessive
requirements on model memory and integration time.

Summary of differences between Wilson and Ballard, 1999 (3B) and 3D schemes
---------------------------------------------------------------------------

The present (3D) scheme was developed in order to incorporate changes
necessary for the PC2 prognostic cloud scheme. It also contain some
important science developments.

Briefly, the scientific differences of the 3D microphysics scheme
compared to the :raw-latex:`\cite{Wilson:Ballard:1999}` paper are:

- Options for two ice quantities and associated particle distributions,
  mass-diameter relationships and fall-speed diameter relationships

- Options for the inclusion of prognostic variables for ice crystals

- A consistent sub grid-scale model for the vapour, liquid, ice and rain
  contents

- A sub grid-scale model for the rain variable

- A change in the parameters specifying the raindrop size distribution

- The autoconversion mechanism allows calculation of droplet
  concentrations from the sulphate aerosol or the ‘MURK’ tracer aerosol

- Changes in the nucleation of ice

- The option of calculating, rather than specifying, ice fall speeds

- Changes to the capacitance of ice particles and use of different
  values for evaporation and deposition

- Latent heat correction to evaporation and deposition transfer limits

- Inclusion of changes to cloud fractions as a result of each transfer
  process

- A change to the sub grid-scale distribution of vapour in the
  non-liquid cloud part of the gridbox

- Optional inclusion of the prognostic representation of rain

- Optional separate prognostic representation of ice crystals and snow
  aggregates

- Optional prognostic representation of graupel

- Optional inclusion of droplet settling for the removal of persistent
  fog

- Optional use of a generic ice particle size distribution
  :raw-latex:`\citep{Field:etal:2005,Field:etal:2007}`

- Improved representation of rain fall speeds
  :raw-latex:`\citep{Abel:Shipway:2007}`

- Improved link between visibility aerosol and droplet number

- Extensive modifications and improvements to the representation of warm
  rain, see Section `5.3 <#sec:warmnew>`__.

There are also changes to the numerical solution of the fall of ice from
level to level.

Model variables
===============

In all simulations, the four quantities vapour, liquid, ice aggregates
and rain all exist. However, there exists the option to select more
detailed microphysical calculations involving prognostic rain and
multiple types of ice particle. This extra detail is intended for use in
high resolution versions of the Unified Model and is closer to the more
cloud resolving model type of formulations, such as
:raw-latex:`\cite{Swann:1996}`. The prognostics in the scheme are
detailed below.

.. _`sec:wvdes`:

Water vapour
------------

**Symbol ‘:math:`q`’, units :math:`kg~kg^{-1}`, code variable
‘:math:`q`’.** This is the vapour mixing ratio and represents the mean
water vapour in the model grid box. It is a prognostic for all options
within the scheme.

Liquid water content
--------------------

**Symbol ‘:math:`q_{cl}`’, units :math:`kg~kg^{-1}`, code variable
‘:math:`qcl`’.** This represents the mean liquid water content in the
model grid box (per kg of moist air). It is a prognostic quantity within
this scheme.

Rain water content and rain rate
--------------------------------

**Symbols ‘:math:`q_R`’ and :math:`R`; code variables ‘:math:`qrain`’
(mixing ratio) and :math:`rainrate` (flux)**

There are two ways in which rain is represented in the UM. It can be
either a prognostic variable and therefore advected by the model winds,
or a diagnostic variable, which is not advected. In the diagnostic
scheme, rain amounts are not allowed to be retained in the model at the
end of the timestep; it is assumed that all rain will have fallen to the
Earth’s surface.

The code uses two variables, :math:`qrain` and :math:`rainrate`. All
transfer processes are performed on :math:`qrain` only. After the
transfer processes have been performed, this is converted to a rain rate
(code symbol :math:`rainrate`).

Diagnostic representation:
~~~~~~~~~~~~~~~~~~~~~~~~~~

**Units :math:`kg~m^{-2}~s^{-1}`.** This represents the flux of rain (or
rain rate) in each model level. There is no advection of rain between
horizontal grid boxes, so any rain generated remain within the same
vertical column of model grid boxes, falling from level to level.
Individual transfer processes (e.g. accretion or evaporation) may
increase or reduce the rain rate, but it is still assumed that at the
end of the timestep, any rain left will have fallen to the Earth’s
surface.

Prognostic representation:
~~~~~~~~~~~~~~~~~~~~~~~~~~

**Units :math:`kg~kg^{-1}`.** This represents the mixing ratio of rain.
This quantity is *advected* downwards in the column to represent its
fall. The prognostic representation means that this representation costs
more in run-time (it needs to be advected by the dynamics).

However, there are a number of advantages of a prognostic rain variable
as opposed to a diagnostic representation. At high resolution rain may
be advected horizontally across many grid boxes as it falls. This could
be significant where the rainfall pattern is stationary for an extended
period of time, or where the interaction of the rainfall and the
updraught/downdraught in a convective cell is important. Vertical
advection from resolved convective updraughts of order 5
ms\ :math:`^{-1}` may be significant in some circumstances. A prognostic
approach also avoids an instantaneous response to the dynamics and may
delay the onset of rainfall in the early stages of a developing
convective storm.

Ice water content
-----------------

**Symbol ‘:math:`q_{cf}`’, Units :math:`kg~kg^{-1}`, code variable
‘:math:`qcf`’** This is the mixing ratio representing the mean ice water
content per kg of moist air in the grid box.

Single prognostic representation:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This quantity is split by a diagnostic relationship into a large-ice
category, *‘aggregates’* (**symbol :math:`q_{cfa}`, code variable
qcf_agg**), and a small-ice category, *‘crystals’* (**symbol
:math:`q_{cfc}`, code variable qcf_cry**) which are then treated
separately by the microphysical transfers before being recombined after
the transfers have been completed.

Prognostic representation of a second ice category
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This allows the large-ice and the small-ice quantities to be carried as
prognostics elsewhere in the model. The transfers are the same as in the
diagnostic scheme but, of course, no diagnostic split is required and no
recombination of the quantities is required. The prognostic
representation was introduced to investigate the necessary level of
complexity required in microphysical schemes and more closely matches
representations within cloud resolving models, such as
:raw-latex:`\cite{Swann:1996}`. This is currently only used as an
experimental option. Unless you have good reason to use it, it is
recommended to use the single prognostic above.

Prognostic representation of graupel:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Symbol :math:`q_{graup}`, units :math:`kg~kg^{-1}`, code variable
:math:`qgraup`** This allows the representation of ice in the form of
graupel, which can occur in deep convective cells. It acts as an
efficient moisture sink due to having a high fall speed relative to rain
and snow. Hence, the representation of this hydrometeor in high
resolution versions of the UM is probably desirable. The most important
microphysical processes associated with graupel have been determined by
:raw-latex:`\cite{Forbes:Halliwell:2003}` from CRM runs of convective
case studies and details of four implemented graupel processes are
described in section `6.3 <#sec:trans_eqs>`__. This option is used
routinely in km-scale simulations in the Met Office operational suite.
There is also the option to increase the production of graupel by
allowing snow-rain collisions to form graupel. A further option allows
improvements to graupel parametrization, by changing the the particle
size distribution to match observations based on work by
:raw-latex:`\cite{Field:etal:2019}`, along with a reduction in the
autoconversion of snow to graupel and setting the graupel collection of
snow term to zero.

.. _`sec:snowdes`:

Snow
----

**Symbol ‘S’, units :math:`kg~m^{-2}~s^{-1}`, code variable ‘snow’**
This simply represents a temporary quantity, namely the amount of ice
that falls from one gridbox to the one immediately below. Its mass is
contained entirely within the ice water content variables and it should
*not* be considered as a separate ice quantity. *The total mass of ice
in a gridbox is therefore given by
:math:`q_{cfa} + q_{cfc} +q_{graup}`*. The *flux* of
:math:`q_{cfa} + q_{cfc}+ q_{graup}` is given by :math:`S`.

.. _`sec:flux_to_m`:

Flux to mixing ratio conversion
-------------------------------

:math:`S` and, in the diagnostic version, :math:`R` are stored as
fluxes, :math:`q`, :math:`q_{cl}` and :math:`q_{cf}` as mixing ratios.
In places in the code we need to convert between mixing ratios and
fluxes. To ensure that water is conserved,the following conversion is
applied to ice passed into the grid box from above:

.. math:: S = \rho  q_{cf} \frac{\Delta z}{\Delta t}

where :math:`S` (in kg m\ :math:`^{-2}` s\ :math:`^{-1}`) is the flux of
:math:`q_{cf}` (in kg kg\ :math:`^{-1}`), which could represent graupel,
crystals or aggregates, :math:`\rho` is the air density (kg
m\ :math:`^{-3}`), :math:`\Delta z` is the thickness of the layer (m)
and :math:`\Delta t` is the model timestep (s). A similar conversion
applies for rain.

Physical constants and equations of state
=========================================

Table `1 <#tab:mic_phys>`__ shows the values of the physical constants
used in the microphysics parametrization. The UM includes a temperature
dependence for the thermal conductivity, dynamic viscosity and
diffusivity terms and an additional pressure dependence for the
diffusivity term :raw-latex:`\citep{Rogers:Yau:1989}`.

The functions :math:`F_{K_a}(T)`, :math:`F_{\mu}(T)` and
:math:`F_{\psi}(T,p)` in the UM are defined as:

.. math::

   F_{K_a}(T) = F_{\mu}(T) = {\left( \frac{T}{T_0} \right)}^{\frac{3}{2}} 
   \left( \frac{393}{T+120} \right),
   \label{eq:mic_conductivity}

.. math::

   F_{\psi}(T,p) = \left( \frac{T}{T_0} \right)^{\frac{3}{2}} 
    \left( \frac{393}{T+120} \right) \left( \frac{p_0}{p} \right),
   \label{eq:mic_diffusivity}

where :math:`T` is the temperature in Kelvin, :math:`T_0` is the
freezing point of water, :math:`p` is the pressure and
:math:`p_0`\ =1000 hPa.

- The Schmidt number used in the definition of the ventilation
  coefficient (see section 6) is defined as :math:`\mu / (\psi \rho)`.
  In the UM, the Schmidt number is taken as 0.6, following
  :raw-latex:`\cite{Rutledge:Hobbs:1983}`.

- The values of latent heat are valid for a temperature of 0C and are
  assumed in the model to be constant for all temperatures (this
  assumption helps to conserve energy in the model).
  **Aside:** In practice, however, these values change with temperature
  and recent research :raw-latex:`\citep{Fukuta:Gramada:2003}` suggests
  the latent heat of fusion decreases dramatically at temperatures below
  :math:`-20`\ C: it is found to be less than half the 0value at
  :math:`-30`\ C. Given that this could significantly affect the latent
  heating in ice cloud and hence affect the cloud dynamics it could be
  important to include this temperature dependence in the vapour
  pressure and latent heats.

.. container:: center

   .. container::
      :name: tab:mic_phys

      .. table:: Values and definitions of physical constants used in
      the microphysics parametrization.

         +----------------+----------------+----------------+----------------+
         | Symbol         | Definition     | Value          | Units          |
         +================+================+================+================+
         | :math:`L_v`    | latent heat of | 2.501\ :m      | J              |
         |                | vapourization  | ath:`\times`\  | kg\            |
         |                |                | 10\ :math:`^6` |  :math:`^{-1}` |
         +----------------+----------------+----------------+----------------+
         | :math:`L_f`    | latent heat of | 3.34\ :m       | J              |
         |                | fusion         | ath:`\times`\  | kg\            |
         |                |                | 10\ :math:`^5` |  :math:`^{-1}` |
         +----------------+----------------+----------------+----------------+
         | :math:`L_s`    | latent heat of | 2.835          | J              |
         |                | sublimation    | :m             | kg\            |
         |                |                | ath:`\times`\  |  :math:`^{-1}` |
         |                |                | 10\ :math:`^6` |                |
         +----------------+----------------+----------------+----------------+
         | :math:`K_a`    | thermal        | 0.024          | J              |
         |                | conductivity   | :mat           | m\             |
         |                | of air         | h:`F_{K_a}(T)` |  :math:`^{-1}` |
         |                |                |                | s\             |
         |                |                |                |  :math:`^{-1}` |
         |                |                |                | K\             |
         |                |                |                |  :math:`^{-1}` |
         +----------------+----------------+----------------+----------------+
         | :math:`\mu`    | dynamic        | 1.717\ :m      | kg             |
         |                | viscosity of   | ath:`\times`\  | m\             |
         |                | air            | 10\ :math:`^{- |  :math:`^{-1}` |
         |                |                | 5} F_{\mu}(T)` | s\             |
         |                |                |                |  :math:`^{-1}` |
         +----------------+----------------+----------------+----------------+
         | :math:`\psi`   | diffusivity of | 2.21\ :math    | m              |
         |                | water vapour   | :`\times`\ 10\ | \ :math:`^{2}` |
         |                | in air         |  :math:`^{-5}  | s\             |
         |                |                | F_{\psi}(T,p)` |  :math:`^{-1}` |
         +----------------+----------------+----------------+----------------+
         | :math:`R`      | gas constant   | 287.05         | J              |
         |                | for dry air    |                | kg\            |
         |                |                |                |  :math:`^{-1}` |
         |                |                |                | K\             |
         |                |                |                |  :math:`^{-1}` |
         +----------------+----------------+----------------+----------------+
         | :math:`\rho_w` | density of     | 1000.0         | kg             |
         |                | liquid water   |                | m\             |
         |                |                |                |  :math:`^{-3}` |
         +----------------+----------------+----------------+----------------+
         | :math:`g`      | acceleration   | 9.80665        | m              |
         |                | due to gravity |                | s\             |
         |                |                |                |  :math:`^{-2}` |
         +----------------+----------------+----------------+----------------+
         | :m             | ratio of       | 0.62198        |                |
         | ath:`\epsilon` | molecular      |                |                |
         |                | weights of     |                |                |
         +----------------+----------------+----------------+----------------+
         |                | water and dry  |                |                |
         |                | air            |                |                |
         +----------------+----------------+----------------+----------------+

The air density is estimated from the virtual temperature equation.

.. math:: \rho = \frac{p}{\left( R T \left( 1 + 0.6 q - q_{cl} - q_{cf} \right) \right)}

where :math:`p` is the pressure (:math:`N~m^{-2}`) and :math:`R` is the
gas constant for dry air (287 :math:`J~kg^{-1}~K^{-1}`). *The factor of
0.6 is strictly the value :math:`(1-\epsilon)/\epsilon`, which is
0.608.* The air density calculated here does not impact on the
conservation properties of the scheme, it is the input mass of air in a
gridbox which is important for this. This is still calculated via the
hydrostatic assumption, which is not ideal for the non-hydrostatic
formulation the Unified Model now uses.

Latent heat correction
----------------------

Many of the transfer processes are limited by the saturation mixing
ratio. In any process which results in a change in phase, latent heat is
produced or removed. This heat will modify the saturation mixing ratio.
This modification can be accounted for in a change from vapour to a
condensate phase by multiplying the available moisture by the correction
factor :math:`a_L`. This is derived in :umdp:‘029‘ (large-scale cloud)
and is approximated in the large-scale precipitation scheme by

.. math:: \frac{1}{a_L} = 1 +  \frac{\epsilon L^2 q_{sat}}{c_p R T^{2}}

where :math:`L` is the latent heat of the phase change, :math:`q_{sat}`
is the saturation mixing ratio over liquid or ice depending on the phase
change, :math:`c_p` is the heat capacity of air at constant pressure and
:math:`R` is the gas constant for dry air. The latent heat correction is
then used to scale the deposition, evaporation and sublimation processes
in the UM transfer rates.

.. _`sec:param_par_char`:

Parametrized Particle Characteristics
=====================================

Particle Size Distribution
--------------------------

The particle size distribution (PSD), :math:`n_x(D)`, for a particle of
diameter, :math:`D` is defined as a gamma function:

.. math::

   n_x(D)=n_{0x} D^{\alpha_x} e^{-\lambda_x D},
   \label{eq:mic_nx}

where :math:`n_{0x}` is the intercept parameter, :math:`\lambda_x` is
the slope parameter, :math:`\alpha_x` is the constant shape parameter.
(:math:`x` can be either :math:`R` for rain, :math:`a` for aggregates,
:math:`c` for ice crystals or :math:`g` for graupel). For a single
moment scheme, the intercept parameter is assumed constant or a simple
function of :math:`\lambda_x`

.. math::

   n_{0x}=n_{ax} \lambda_x^{n_{bx}}
      \label{eq:mic_nx0s}

where :math:`n_{ax}` and :math:`n_{bx}` are constants.
Table `2 <#tab:mic_consts_psd>`__ shows the values of the above
constants for the large-scale precipitation scheme.

.. container:: center

   .. container::
      :name: tab:mic_consts_psd

      .. table:: Default values of constants used in the particle
      size-spectra relations. The rain parameters were selected
      specifically in order to produce smaller drop sizes for lighter
      rain, as demonstrated from radar data. The parametrization of the
      crystal size distribution follows the form of
      :raw-latex:`\cite{Cox:1988}` but uses aircraft data from
      :raw-latex:`\cite{Field:1999}` to influence the choice of the
      values of the parameters.

         +----------+----------+----------+----------+----------+----------+
         | Model    | :math:   | :math:   |          | :math:`\ | R        |
         |          | `n_{ax}` | `n_{bx}` |          | alpha_x` | eference |
         +==========+==========+==========+==========+==========+==========+
         | Rain     | :mat     | 2        | 2        | 0.0      | :raw     |
         |          | h:`0.22` |          |          |          | -latex:` |
         |          |          |          |          |          | \cite{Ab |
         |          |          |          |          |          | el:Boutl |
         |          |          |          |          |          | e:2012}` |
         +----------+----------+----------+----------+----------+----------+
         | Ag       | :        | 0        | 0        | 0.0      | :raw     |
         | gregates | math:`2. |          |          |          | -latex:` |
         |          | 0 \times |          |          |          | \cite{Co |
         |          |  10^{6}  |          |          |          | x:1988}` |
         |          | F_{n_{ax |          |          |          |          |
         |          | }}(T_c)` |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | Crystals | :m       | 0        | 0        | 0.0      | Inves    |
         |          | ath:`40. |          |          |          | tigation |
         |          | 0 \times |          |          |          | by       |
         |          |  10^{6}  |          |          |          | Wilson   |
         |          | F_{n_{ax |          |          |          |          |
         |          | }}(T_c)` |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | Graupel  | :math:`5 | :m       | :        | 2.5      | :raw-lat |
         | (i)      |  \times  | ath:`-4` | math:`0` |          | ex:`\cit |
         |          | 10^{25}` |          |          |          | e{Ferrie |
         |          |          |          |          |          | r:1994}` |
         +----------+----------+----------+----------+----------+----------+
         | Graupel  | :        | :m       | :m       | 0.0      | :ra      |
         | (ii)     | math:`7. | ath:`-2` | ath:`58` |          | w-latex: |
         |          | 9 \times |          |          |          | `\cite{F |
         |          |  10^{9}` |          |          |          | ield:eta |
         |          |          |          |          |          | l:2019}` |
         +----------+----------+----------+----------+----------+----------+

The functions :math:`F_{n_{ax}}(T_c)` represent the observed broadening
of the size spectra with increasing temperature for ice particles (due
to the aggregation process). It is defined as:

.. math::

   F_{n_{ax}}(T_c) = \exp\left(- \frac{\mbox{\footnotesize \sf MAX} \left[T_c, -45^{\circ}\mathrm{C}\right]  }
   {8.18^{\circ}\mathrm{C}}\right),

where :math:`T_c` is the temperature in degrees Celsius. This form was
selected after comparison with aircraft data: see, for example,
:raw-latex:`\cite{Field:1999, Field:2000}`.

Two choices are available for the graupel particle size distribution are
available; these are denoted as (i) and (ii) in table
`2 <#tab:mic_consts_psd>`__ above. The first, (i) is the original scheme
as included by :raw-latex:`\cite{Forbes:Halliwell:2003}`, however this
was found to produce a lot of small graupel particles, even when larger
graupel mass were present in severe convective storms. A new particle
size distribution has been developed by
:raw-latex:`\cite{Field:etal:2019}` which shows better agreement with
aircraft data.

Splitting of ice into aggregates and crystals
---------------------------------------------

In the version of the scheme where there is only one ice prognostic,
:math:`q_{cf}`, this is split between the aggregates :math:`q_{cfa}` and
crystals :math:`q_{cfc}` using the following diagnostic function.

.. math::

   f_{aggregates} = 1 - \exp \left( - T_{scaling} (T-T_{CT}) q_{cf} / q_{cf0} \right)
   \label{eq:cry_agg_split}

where :math:`(T-T_{CT})` is the temperature difference from the cloud
top. :math:`T_{CT}` is calculated as the temperature of the first layer
counting upwards which did not have snow falling into it.
:math:`T_{scaling}` and :math:`q_{cf0}` are specified parameters (see
table `3 <#tab:mic_split>`__) and :math:`f_{aggregates}` is the fraction
of :math:`q_{cf}` that is apportioned to the aggregate part of the
particle size distribution. This formulation was developed by Wilson and
is based upon both aircraft data (for example,
:raw-latex:`\citealp{Field:1999}`) and modelling data
:raw-latex:`\citep{Cardwell:etal:2002}`. The flux of snow that is
carried between model levels represents the combined fluxes of both
aggregates and crystals. When snow falls into a layer it is assumed to
be distributed between aggregates and crystals according to the
partition of the layer into which it falls. At the end of the
microphysics routine the final values of :math:`q_{cfa}` and
:math:`q_{cfc}` are added together to reform :math:`q_{cf}` which is
then used as a single quantity in the rest of the model.

.. container:: center

   .. container::
      :name: tab:mic_split

      .. table:: Parameters for the splitting of ice into crystals and
      aggregates.

         =================== ===============================================
         :math:`T_{scaling}` 0.0384 K\ :math:`^{-1}`
         =================== ===============================================
         :math:`q_{cf0}`     :math:`1.0 \times 10^{-4}` kg kg\ :math:`^{-1}`
         =================== ===============================================

.. _`sec:field_psd`:

Generic Ice Particle Size Distributions 
----------------------------------------

Following the work of :raw-latex:`\cite{Field:etal:2005}`, the option is
now available to include a generic ice particle size distribution for
aggregates only.

.. _`sec:field_psd_ml`:

Mid-latitude version
~~~~~~~~~~~~~~~~~~~~

Using aircraft data over large areas around the British Isles,
:raw-latex:`\cite{Field:etal:2005}` show that the ice particle size
distribution all have bimodal distributions. It is possible to relate
any moment of the distribution (for example, the zeroth moment, which is
usually number concentration) to the second moment (directly
proportional to ice water content) as a power law as follows:

.. math::

   \label{eq:field1}
   \mathcal{M}_{\hat{n}} = \hat{a}(\hat{n}, T_c)\mathcal{M}_2^{\hat{b}(\hat{n}, T_c)}

where :math:`\mathcal{M}_{\hat{n}}` is moment of the distribution of
order :math:`\hat{n}` and :math:`T_c` is the temperature in degrees
Celsius. The parameters :math:`\hat{a}` and :math:`\hat{b}` are
determined using the formulae

.. math::

   \begin{aligned}
   \label{eq:fielda}
   \log_{10} \hat{a}(\hat{n}, T_c) &=& \hat{a}1 + \hat{a}_2 T_c + \hat{a}_3 \hat{n} 
   + \hat{a}_4 T_C \hat{n} \nonumber \\
   & & + \hat{a}_5 T_C^2 + \hat{a}_6 \hat{n}^2 + \hat{a}_7 T_c^2 \hat{n} \nonumber \\
   & & + \hat{a}_8 T_c \hat{n}^2 + \hat{a}_9 T_C^3 + \hat{a}_{10} \hat{n}^3 
   \end{aligned}

.. math::

   \begin{aligned}
   \label{eq:fieldb}
   b(\hat{n}, T_c) &=& b_1 + b_2 T_c + b_3 \hat{n} + b_4 T_c \hat{n} \nonumber \\
   & & + b_5 T_c^2 + b_6 \hat{n}^2 + b_7 T_c^2 \hat{n} \nonumber \\
   & & + b_8 T_c \hat{n}^2 + b_9 T_c^3 + b_{10}\hat{n}^3
   \end{aligned}

with the values of :math:`a_z` and :math:`b_z` where :math:`z`
represents the subscripts 1 to 10 are given in table `4 <#tab:field>`__.

.. container:: center

   .. container::
      :name: tab:field

      .. table:: Coefficients and exponents of moment for equations
      `[eq:fielda] <#eq:fielda>`__ and `[eq:fieldb] <#eq:fieldb>`__.

         ========= ============ ====== ============ ======
         :math:`z` :math:`a_z`         :math:`b_z`  
         ========= ============ ====== ============ ======
         1         5            065339 0            476221
         2         :math:`-`\ 0 062659 :math:`-`\ 0 015896
         3         :math:`-`\ 3 032362 0            165977
         4         0            029469 0            007468
         5         :math:`-`\ 0 000285 :math:`-`\ 0 000141
         6         0            312550 0            060366
         7         0            000204 0            000079
         8         0            003199 0            000594
         9         0            000000 0            000000
         10        :math:`-`\ 0 015951 :math:`-`\ 0 003577
         ========= ============ ====== ============ ======

.. _`sec:field_psd_gl`:

Global version
~~~~~~~~~~~~~~

As an extension to the :raw-latex:`\cite{Field:etal:2005}` work,
:raw-latex:`\cite{Field:etal:2007}` developed an extension to the 2005
parametrization but based on a global aircraft data set. The new
parametrization is of the form

.. math::

   \label{eq:field2}
   \mathcal{M}_{\hat{n}} = \hat{d}(\hat{n})~\exp(~\hat{e}T_c~)~
   \mathcal{M}_2^{\hat{f}(\hat{n})}

where the parameters :math:`\hat{d}`, :math:`\hat{e}` and
:math:`\hat{f}` can be determined as exponential and quadratic functions
of :math:`\hat{n}` as follows:

.. math::

   \begin{aligned}
   \label{eq:field2d}
   \hat{d}(\hat{n})=\exp(~13.6-7.76\hat{n}+0.479\hat{n}^2~) \nonumber \\
   \hat{e}(\hat{n})=-0.0361 + 0.0151\hat{n}+0.00149\hat{n}^2 \nonumber \\
   \hat{f}(\hat{n})=0.807 + 0.00581\hat{n} + 0.0457\hat{n}^2 .
   \end{aligned}

The global version should revert to the same results as the mid-latitude
version in a mid-latitude limited area model, although this has yet to
be proven within the UM.

.. _`sec:field_psd_fc`:

Further comments relevant to both versions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In the transfer equations for ice, (described in more detail in section
`6.3 <#sec:trans_eqs>`__), it is possible to use various different
moments of the particle size distribution to obtain the transfer rates,
without having to make assumptions about the intercept parameters of the
distribution using the ice water content. These are discussed in turn in
section `6.3 <#sec:trans_eqs>`__.

Note that the generic ice particle size distribution includes the effect
of crystals within the formulation and hence it is not possible to use
both the generic ice particle size distribution and the inclusion of
crystals in the UM at the same time.

Terminal Fall Speed
-------------------

The terminal fall velocity of a precipitating particle, :math:`V_x(D)`
can be expressed as a function of diameter:

.. math::

   V_x(D)=c_xD^{d_x} e^{-h_xD} \left( \frac{\rho_0}{\rho}\right) ^{\mathcal{G}_x}
   \label{eq:mic_vxd}

where :math:`c_x`, :math:`d_x`, :math:`h_x` and :math:`\mathcal{G}_x`
are constants (see Table `5 <#tab:mic_consts_fallspeed>`__) and
:math:`\rho_0` is a reference density of 1 :math:`kg~m^{-3}`. The scheme
also has the option to specify the parameters :math:`c_x` and
:math:`d_x` by using knowledge of their area-diameter relationships and
a Best number (:math:`B_e`)- Reynolds number (:math:`R_e`) relationship
as described by :raw-latex:`\cite{Mitchell:1996}`.

.. math::

   c_x=e_x \mu_0^{(1-2f_x)} \rho_0^{(f_x-1)}(2 g)^{f_x}  \left(
      \frac{a_x}{r_x}\right) ^{f_x}

.. math:: d_x=f_x (b_x + 2 - s_x) - 1

where :math:`\mu_0` is the dynamic viscosity of air at
0\ :math:`^{\circ}`\ C, :math:`g` is the acceleration due to
gravity [1]_ and

.. math:: A_{ice}=r_x D^{s_x}

where :math:`A_{ice}` is the maximum cross-sectional area of an ice
particle and

.. math:: R_e=e_x B_e^{f_x}

where parameters are given in tables `5 <#tab:mic_consts_fallspeed>`__,
`6 <#tab:mic_consts_fallspeed2>`__, `9 <#tab:mic_consts_density>`__ and
`10 <#tab:bf95>`__.

.. container:: center

   .. container::
      :name: tab:mic_consts_fallspeed

      .. table:: Default values of constants used in the fall speed
      relations. The :raw-latex:`\cite{Sachidananda:Zrnic:1986}`
      relationship does not asymptote to a fixed value for large
      diameters and better representations exist; these are discussed
      further in section `4.4.3 <#sec:as07>`__. The ice fall speeds are
      selected so as to agree with the values calculated using the
      :raw-latex:`\cite{Mitchell:1996}` relationships.

         +----------+----------+----------+----------+----------+----------+
         | Model    | :ma      | :ma      | :math    | :ma      | R        |
         |          | th:`c_x` | th:`d_x` | :`\mathc | th:`h_x` | eference |
         |          |          |          | al{G}_x` |          |          |
         +==========+==========+==========+==========+==========+==========+
         | Rain     | 386.8    | 0.67     | 0.4      | 0.0      | :ra      |
         |          |          |          |          |          | w-latex: |
         |          |          |          |          |          | `\cite{S |
         |          |          |          |          |          | achidana |
         |          |          |          |          |          | nda:Zrni |
         |          |          |          |          |          | c:1986}` |
         +----------+----------+----------+----------+----------+----------+
         | Ag       | 14.3     | 0.416    | 0.4      | 0.0      | :        |
         | gregates |          |          |          |          | raw-late |
         |          |          |          |          |          | x:`\cite |
         |          |          |          |          |          | {Mitchel |
         |          |          |          |          |          | l:1996}` |
         +----------+----------+----------+----------+----------+----------+
         | Crystals | 74.5     | 0.640    | 0.4      | 0.0      | :        |
         |          |          |          |          |          | raw-late |
         |          |          |          |          |          | x:`\cite |
         |          |          |          |          |          | {Mitchel |
         |          |          |          |          |          | l:1996}` |
         +----------+----------+----------+----------+----------+----------+
         | Graupel  | 253.0    | 0.734    | 0.4      | 0.0      | :raw-lat |
         |          |          |          |          |          | ex:`\cit |
         |          |          |          |          |          | e{Ferrie |
         |          |          |          |          |          | r:1994}` |
         +----------+----------+----------+----------+----------+----------+

.. container:: center

   .. container::
      :name: tab:mic_consts_fallspeed2

      .. table:: Constants used in the calculation of ice crystal and
      aggregate fall speed relationships. Graupel, like rain is assumed
      to be spherical; hence it is not possible to set values for the
      constants in this table for these quantities.

         +----------+----------+----------+----------+----------+----------+
         | Species  | :ma      | :ma      | :ma      | :ma      | R        |
         |          | th:`e_x` | th:`f_x` | th:`r_x` | th:`s_x` | eference |
         +==========+==========+==========+==========+==========+==========+
         | Ag       | 0.2072   | 0.638    | 0.131    | 1.88     | :        |
         | gregates |          |          |          |          | raw-late |
         |          |          |          |          |          | x:`\cite |
         |          |          |          |          |          | {Mitchel |
         |          |          |          |          |          | l:1996}` |
         +----------+----------+----------+----------+----------+----------+
         | Crystals | 0.2072   | 0.638    | 0.131    | 1.88     | :        |
         |          |          |          |          |          | raw-late |
         |          |          |          |          |          | x:`\cite |
         |          |          |          |          |          | {Mitchel |
         |          |          |          |          |          | l:1996}` |
         +----------+----------+----------+----------+----------+----------+

.. _`sec:mit_2nd_rex`:

Crystal fall speed relations using Mitchell (1996)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recently, the :raw-latex:`\cite{Brown:Francis:1995}` ice particle
densities have been used operationally in the UM (see section
`4.5.1 <#sec:bf95>`__ for further details). If the
:raw-latex:`\cite{Brown:Francis:1995}` particle densities are used, the
2nd Re-X (:math:`R_e`\ :math:`B_e` in this document) relation (Eq.19) of
:raw-latex:`\cite{Mitchell:1996}` **must** also be used to ensure the
crystal velocities are correct, when crystals are used in the model.

So, when :raw-latex:`\cite{Brown:Francis:1995}` densities are being
used, the last line of table `6 <#tab:mic_consts_fallspeed2>`__ should
be replaced by that in table `7 <#tab:mit_2nd_rex>`__.

.. container:: center

   .. container::
      :name: tab:mit_2nd_rex

      .. table:: Parameters for use in the 2nd Re-X
      (:math:`R_e`\ :math:`B_e` in this document) relation (Eq.19) of
      :raw-latex:`\cite{Mitchell:1996}`; now operational in the NWP
      suite.

         +----------+----------+----------+----------+----------+----------+
         | Species  | :ma      | :ma      | :ma      | :ma      | R        |
         |          | th:`e_x` | th:`f_x` | th:`r_x` | th:`s_x` | eference |
         +==========+==========+==========+==========+==========+==========+
         | Crystals | 0.06049  | 0.831    | 0.131    | 1.88     | :        |
         |          |          |          |          |          | raw-late |
         |          |          |          |          |          | x:`\cite |
         |          |          |          |          |          | {Mitchel |
         |          |          |          |          |          | l:1996}` |
         +----------+----------+----------+----------+----------+----------+

.. _`sec:split_ice_vt`:

Splitting the ice fallspeeds with the Generic PSD
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Generic PSD described in section (`4.3 <#sec:field_psd>`__) uses a
single size distribution to describe the whole particle population. In
contrast the exponential PSD splits the total ice water content in each
grid box into ice and aggregate categories. Hence for the exponential
PSD different fallspeed-diameter relations can be specified for the two
categories. To allow this level of flexibility with the Generic PSD we
use the following formulation.

Two different :math:`V_t-D` relations can be specified and these are
used individually to calculate two candidate mass-weighted mean
fallspeeds in each grid box. Denoting the two relations by

.. math::

   \begin{aligned}
   \label{eq:split_vtd}
   V_t = c_1 D^{d_1}, \\
   V_t = c_2 D^{d_2}
   \end{aligned}

(neglecting the associated factors of air density), the two candidate
mass-weighted mean fallspeeds are given by

.. math::

   \begin{aligned}
   \label{eq:split_vm}
   \rho q_{cf} [V]^{(1)}_{q_{cf}} = a{\cal M}_{b+d_1}(q_{cf},T_c),\\
   \rho q_{cf} [V]^{(2)}_{q_{cf}} = a{\cal M}_{b+d_2}(q_{cf},T_c).
   \end{aligned}

In each grid box the :math:`V_t-D` relation is selected which gives the
*least* mass-weighted mean fallspeed. The selected fallspeed is then
used for all ice-microphysical process rate calculations for that grid
box on that timestep. This includes sedimentation, but also depositional
growth (where :math:`V_t` affects the ventilation), riming and so on.

.. _`sec:as07`:

Abel and Shipway rain fall speeds
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This changes the standard rain fall speeds (equation
`[eq:mic_vxd] <#eq:mic_vxd>`__, with values from
:raw-latex:`\citealp{Sachidananda:Zrnic:1986}`) to the relation in
appendix of :raw-latex:`\cite{Abel:Shipway:2007}`:

.. math::

   \label{eq:as07}
   V_R(D)=\left[c_{1R}D^{d_{1R}} e^{-h_{1R}D} + c_{2R}D^{d_{2R}} e^{-h_{2R}D} 
   \right] \left( \frac{\rho_0}{\rho}\right) ^{\mathcal{G}_{R}}

where the subscript :math:`R` is used instead of :math:`x` as this
change only applies to rain. The value of the constants used is given in
table `8 <#tab:as07>`__. It should be noted that while
:raw-latex:`\cite{Abel:Shipway:2007}` set :math:`\mathcal{G}_R` to be
0.5, following the practice of the Met Office Large Eddy Model (LEM), we
have retained the value of 0.4 to maintain consistency with the rest of
the UM, as defined in table `5 <#tab:mic_consts_fallspeed>`__.

.. container:: center

   .. container::
      :name: tab:as07

      .. table:: Parameters used in the
      :raw-latex:`\cite{Abel:Shipway:2007}` rain fall velocity (equation
      `[eq:as07] <#eq:as07>`__) as set-up for the UM. Note that
      parameter :math:`c_{2R}` differs from
      :raw-latex:`\cite{Abel:Shipway:2007}` as there is a mistake in
      their paper where they give this term the wrong sign. The version
      used here and in the UM is correct.

         +-------+-------+-------+-------+-------+-------+-------+-------+
         | Para  | :mat  | :mat  | :mat  | :mat  | :mat  | :mat  | :     |
         | meter | h:`c_ | h:`d_ | h:`h_ | h:`c_ | h:`d_ | h:`h_ | math: |
         |       | {1R}` | {1R}` | {1R}` | {2R}` | {2R}` | {2R}` | `\mat |
         |       |       |       |       |       |       |       | hcal{ |
         |       |       |       |       |       |       |       | G}_R` |
         +=======+=======+=======+=======+=======+=======+=======+=======+
         | Value | 4     | 1.00  | 195.0 | :     | 0.7   | 40    | 0.4   |
         |       | 854.1 |       |       | math: | 82127 | 85.35 |       |
         |       |       |       |       | `-446 |       |       |       |
         |       |       |       |       | .009` |       |       |       |
         +-------+-------+-------+-------+-------+-------+-------+-------+

The inclusion of these extra parameters allows a precise fit to the
rainfall observations of :raw-latex:`\cite{Beard:1976}`. The
:raw-latex:`\cite{Sachidananda:Zrnic:1986}` in the UM provides a good
fit to the fall velocity of rain, but for smaller drizzle drops, the
fall speed is overestimated by as much as a factor of ten. Simple tests
using the 1D explicit microphysics model of
:raw-latex:`\cite{Wilkinson:etal:2010:qj}` and the 1D KiD model
:raw-latex:`\citep{Shipway:Hill:2011}` have indicated that this should
improve the representation of drizzle in the UM. The scheme works in one
of two ways:

- **Prognostic Rain** In this case, the
  :raw-latex:`\cite{Sachidananda:Zrnic:1986}` relation is replaced by
  the :raw-latex:`\cite{Abel:Shipway:2007}` fall velocity in every
  instance that a rain velocity assumption is made in the code. The
  largest impact is in the ‘fall’ routine, where the rain falls out from
  one layer to the next. This determines how long the rain content
  remains in each layer. Use of the new
  :raw-latex:`\cite{Abel:Shipway:2007}` relation allows rain to remain
  in the column for longer, thus allowing more time for the small drops
  to evaporate.

- **Diagnostic Rain** In this case, all rain is assumed to fall out in
  one timestep, irrespective of the size of the drops, so altering the
  fall speed of rain will have little impact. To get around this
  problem, the code examines the difference in fall velocity between the
  :raw-latex:`\cite{Sachidananda:Zrnic:1986}` and
  :raw-latex:`\cite{Abel:Shipway:2007}` relations. The ratio of the two
  velocities is used to enhance the evaporation rate, such that light
  drizzle rates are evaporated more readily, whilst the heavier rain
  rates remain unaffected. For consistency, the
  :raw-latex:`\cite{Abel:Shipway:2007}` relation is also applied
  throughout the code wherever a transfer involves a rain-rate
  assumption.

.. _`sec:density`:

Density Distribution
--------------------

The mass-diameter relation for rain simply assumes a spherical drop with
a density equal to that for liquid water, 1000 kg m\ :math:`^{-3}`.
Similarly, the mass-diameter relation for graupel simply assumes a
spherical particle with a density equal to 500 kg m\ :math:`^{-3}`.

For other ice species, we assume a power law relating the mass of the
particle to the diameter.

.. math::

   \label{eq:m_x}
   M_x(D)=a_x D^{b_x}

Although this can result in ice particle densities that get above that
for solid ice, this enables the power law representation allows the
microphysical transfer rates to be solved easily.

.. container:: center

   .. container::
      :name: tab:mic_consts_density

      .. table:: Default values of constants used in the density
      relations.

         +------------+-------------+-------------+--------------------------+
         | Species    | :math:`a_x` | :math:`b_x` | Reference                |
         +============+=============+=============+==========================+
         | Aggregates | 0.0444      | 2.1         | based on                 |
         |            |             |             | :raw-latex:`\cit         |
         |            |             |             | e{Locatelli:Hobbs:1974}` |
         +------------+-------------+-------------+--------------------------+
         | Crystals   | 0.587       | 2.45        | Similar to table 1 of    |
         |            |             |             | :raw-late                |
         |            |             |             | x:`\cite{Mitchell:1996}` |
         +------------+-------------+-------------+--------------------------+

.. _`sec:bf95`:

Brown and Francis ice particle densities
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An alternative density function to the default one used in the UM has
been derived by :raw-latex:`\cite{Brown:Francis:1995}`, following
:raw-latex:`\cite{Locatelli:Hobbs:1974}`. The relation gives better
agreement with aircraft measurements of ice and has been shown by
:raw-latex:`\cite{Wilkinson:2007}` to give better agreement with radar
reflectivity measured by the Chilbolton 94–GHz radar. Use of
:raw-latex:`\cite{Brown:Francis:1995}` reduces the density by
approximately a factor of four, but dependent on size. The parameters
for :math:`a_x` and :math:`b_x` (after translation into SI units) are
given in table `10 <#tab:bf95>`__.

.. container:: center

   .. container::
      :name: tab:bf95

      .. table:: Values of density relations used by
      :raw-latex:`\cite{Brown:Francis:1995}`

         +------------+-------------+-------------+----------------------------------------+
         | Species    | :math:`a_x` | :math:`b_x` | Reference                              |
         +============+=============+=============+========================================+
         | Aggregates | 0.0185      | 1.90        | :raw-latex:`\cite{Brown:Francis:1995}` |
         +------------+-------------+-------------+----------------------------------------+
         | Crystals   | 0.0185      | 1.90        | :raw-latex:`\cite{Brown:Francis:1995}` |
         +------------+-------------+-------------+----------------------------------------+

These parameters have been adopted for use in the current operational UM
and can be set in the gui/namelist.

If the density is changed to :raw-latex:`\cite{Brown:Francis:1995}`,
then the 2nd Re-X (:math:`R_e`\ :math:`B_e` in this document) relation
(Eq.19) of :raw-latex:`\cite{Mitchell:1996}` **must** also be used.
Section `4.4.1 <#sec:mit_2nd_rex>`__ contains details on how to do this.

.. _mr2psd:

Inferring particle size distributions from mixing ratios and fluxes
-------------------------------------------------------------------

In order to solve for the microphysical transfer rates it is necessary
to be able to infer the particle size distribution in terms of mixing
ratios and fluxes. The exception to this is when the generic ice
particle size distribution is being used (see section
`4.3 <#sec:field_psd>`__ for details). We can do this by integrating the
mass-diameter relationship across the particle-size distribution
relationship. For fluxes we also weight by the fall-speed relationship.
For the flux description of the rainfall rate we have:

.. math::

   R = \int_{D_R = 0}^{D_R = \infty} \frac{\pi}{6} 
   \rho_w {D_R}^3 c_R ~ D_R^{d_R} \left(\frac{\rho_0}{\rho}\right)^{\mathcal{G}_R}  
   N_R(D_R) dD_R

where :math:`R` is the rainfall rate (in kg m\ :math:`^{-2}`
s\ :math:`^{-1}`). Using the description of the raindrop size
distribution

.. math::

   N_R (D_R) = n_{aR} \lambda_R ^{n_{br}}  D_R ^{\alpha_R} \exp 
   \left( - \lambda_R D_R \right)

and solving the integral for :math:`\lambda_R` gives the result

.. math::

   \lambda_R = { \left( \frac { \pi ~c_R~ { \left( \frac{\rho_0}{\rho} \right) }
   ^{\mathcal{G}_R} \rho_w n_{aR} \Gamma \left( 4 + \alpha_R +d_R \right) } 
   {6 R} \right) } ^ { \frac{1}{4 + d_R + \alpha_R - n_{br}} } .

A full derivation of this is available in appendix I.

This will define the raindrop size distribution for a given :math:`R`
and will be used as part of the calculation of transfer rates for the
microphysical processes. A similar calculation can be performed for the
ice aggregate content:

.. math:: q_{cfa} = \frac{1}{\rho} \int_{D_a = 0}^{D_a = \infty} a_a~D_a^{b_a} N_a(D_a) dD_a

where :math:`q_{cfa}` is the ice water mixing ratio in the aggregates
(in :math:`kg~kg^{-1}`). This solves for :math:`\lambda_a` as:

.. math::

   \lambda_a = 
   { \left( \frac {n_{aa} a_a \Gamma(b_a + 1 + \alpha_a) } { \rho q_{cfa} } \right) }
   ^{ \frac{1}{b_a+1+\alpha_a-n_{ba}} }

and similarly for :math:`\lambda_c`:

.. math::

   \lambda_c = 
   { \left( \frac {n_{ac} a_c \Gamma(b_c+1+\alpha_c) } { \rho q_{cfc} } \right) }
   ^{ \frac{1}{b_c+1+\alpha_c-n_{bc}} }

and finally for :math:`\lambda_g`:

.. math::

   \lambda_g =
   { \left( \frac {n_{ag} a_g \Gamma(b_g+1+\alpha_g) } { \rho q_{graup} } \right) }
   ^{ \frac{1}{b_g+1+\alpha_g-n_{bg}} } .

The microphysical transfer processes modelled are generally solved by
performing similar integrals over the particle size distribution.

.. _`sec:subgrid`:

Sub Grid-scale treatment
========================

Gridbox partitions
------------------

Gridbox partitions are used in the precipitation schemes. The grid boxes
in the model represent areas which can be several hundred kilometres
across. Such a gridbox will contain a very large degree of heterogeneity
in its cloud field. The microphysical transfer rates that are calculated
are thus not directly applicable to the whole gridbox.

The schemes divide the grid box into eight regions, representing the
possible states of presence or absence of ice  [2]_, liquid water and
rain. (Thus there are three phases each with 2 options, present or
absent and :math:`2^3=8`.) In order to calculate the size of these
partitions we need to know information about the ice cloud fraction (by
volume), :math:`C_i`, the liquid cloud fraction, :math:`C_l`, the rain
fraction, :math:`C_R`, and how these are overlapped with each other. The
microphysics scheme will be provided with information from the
large-scale cloud scheme about not only :math:`C_i` and :math:`C_l`, but
also their combined cloud fraction :math:`C`. Hence it is possible to
calculate their overlap as:

.. math:: C_{mixed~phase} = C_i + C_l - C .

There is an assumption about the overlap of the ice cloud and liquid
cloud but this is made in the large-scale cloud scheme (the default
setting of this is for minimum overlap). The rain fraction will be
calculated within the microphysics scheme along with the rain flux. It
is assumed to overlap according to the rules below, applied in the order
they are shown:

#. Firstly, maximally with liquid-only cloud

#. Then maximally with mixed-phase cloud

#. Finally, maximally with ice-phase cloud.

The transfer processes are then solved over each of the eight possible
partitions, assuming a uniform distribution of ice water content across
the part of the grid box which contains ice cloud (and similar uniform
assumptions for liquid water and rain). Since many of the eight
partitions will produce either zero transfer or identical transfers, the
calculation can usually be condensed into solving for just one partition
and multiplying by the fraction of the gridbox containing the relevant
partitions.

Vapour distribution
-------------------

We assume that there is no temperature or pressure distribution across
the gridbox. The assumption of instantaneous condensation will fix the
vapour content within liquid cloud to :math:`q_{sat~water} ({T}, {p})`.
However, no similar assumption can be made for ice, indeed if we did
then we could not grow ice by deposition or sublimation. To close the
problem we will parametrize the vapour content in the clear (no liquid
or ice cloud) part of the gridbox. We will make the assumptions, which
are first stated for the case when there is no liquid water in the
gridbox.

- If :math:`C` is zero then the mean value of vapour content in the
  clear sky part of the gridbox is equal to :math:`q`. This is required
  by conservation of vapour.

- If :math:`C` is one then we will choose to parametrize the vapour
  content in the clear sky part of the gridbox as
  :math:`RH_c q_{sat~ice}`, where :math:`RH_C` is the critical relative
  humidity, at which cloud begins to form.

- There is a linear change with :math:`C` between these two fixed
  values.

Including the possibility of liquid water cloud, where we know the local
value of :math:`q` is equal to :math:`q_{sat~water}`, and combining the
above into equation form, gives

.. math::

   q_{clear} = \frac { C_{ice~only} RH_{c} q_{sat~ice}  ~+~ C_{clear} q_a }
   {C_{ice~only}+C_{clear} }

where :math:`C_{ice~only}` is the fraction of the gridbox with ice cloud
but not liquid cloud, :math:`C_{clear}` is the fraction of the gridbox
with neither liquid nor ice cloud, :math:`RH_c` is the critical relative
humidity parameter and :math:`q_a` is the average vapour content in the
partitions without liquid cloud (hence if there is no liquid cloud then
:math:`q_a = q`). :math:`q_{a}` is given by

.. math:: q_a = \frac { q -  C_l q_{sat~water} } {1 - C_l} .

If :math:`q_{clear}` is less than :math:`RH_c q_{sat~ice}` then a
uniform distribution of vapour is assumed across the liquid-free part of
the gridbox, with no difference between the ice cloud and the clear sky.
The vapour content in the ice-cloud-only partition, :math:`q_{ice~only}`
can then be specified from the values in the remaining partitions:

.. math::

   q_{ice~only} = \frac { q - C_l q_{sat~water} - C_{clear} q_{clear} } 
   { C_{ice~only}} .

Note that :math:`q_{ice~only}` is not allowed to exceed
:math:`q_{sat~water}`. If it does then the surplus is added to
:math:`q_{clear}`.

**Simplifed vapor distribution**

An option is available to simplify the subgrid partitioning of water
vapor so that the specific humidity is the same everywhere outside of
liquid cloud. This is selected by setting the logical ``l_subgrid_qv``
to be *FALSE* in the ``run_cloud`` namelist (to turn off the subgrid
distribution of water vapor). In this case the clear-sky and ice-only
cloud specific humidities are given by

.. math:: q_{clear} =  q_{ice~only} = q_a.

This option also removes the partitioning of water vapor *within* the
ice-only cloud, hence all the ice-only cloud will either be sublimating
or growing by vapor deposition, depending on whether :math:`q_a` is
greater or less than the saturated specific humidity with respect to
ice.

.. _`sec:warmnew`:

Improved Warm Rain Microphysics Scheme
--------------------------------------

From version 8.4, an option for an improved warm rain microphysics
scheme is available through the gui/namelist. This changes the
autoconversion (Sec `6.3.30 <#sec:PRAUT>`__) and accretion
(Sec `6.3.29 <#sec:PRACW>`__) parametrizations, and corrects bugs in the
evaporation (Sec `6.3.28 <#sec:PREVP>`__) and sedimentation
(Sec `6.3.3 <#sec:PRFALL>`__) parametrizations. Furthermore, it improves
the sub-grid treatment of the warm rain microphysics, which is important
due to the highly nonlinear nature of many of the process rates.
:raw-latex:`\cite{boutle:etal:2014}` gives full details, but we
summarise the results here.

For any microphysical process rate of the form :math:`M=aq^b`, for some
constants :math:`a` and :math:`b` and a local quantity :math:`q`, the
grid-box mean process rate :math:`\overline{M}=\overline{aq^b}` does not
equal that obtained from the grid-box mean value of :math:`q`,
i.e. :math:`a\overline{q}^b`, unless :math:`b=1` or there is no
variability in :math:`q` at the sub-grid scale. For microphysics,
typically neither of these conditions are met, and therefore a
representation of the sub-grid variability is required. The one chosen
here is to assume that :math:`q` follows a log-normal distribution at
the sub-grid scale:

.. math::

   \label{eq-lognorm}
     P(q)=\frac{1}{\sqrt{2\pi}\sigma q}\exp\left(-\frac{(\ln q-\mu)^2}{2\sigma^2}\right),

where :math:`\mu=\ln(\bar{q}(1+f^2)^{-1/2})` and
:math:`\sigma^2=\ln(1+f^2)`, allowing us to characterise the sub-grid
variability entirely in terms of :math:`f`, the fractional standard
deviation of :math:`q`. By integrating the process rate over this
distribution, we find that the un-biased process rate is given by
:math:`\overline{M}=E(f,b)a\overline{q}^b`, where

.. math::

   \label{eq-lncorr}
     E(f,b)=(1+f^2)^{-b/2}(1+f^2)^{b^2/2}.

This analytical correction method can easily be extended to multiple
variables with a joint probability distribution function and some
correlation (:math:`\rho`). The improved warm rain scheme applies this
representation of the sub-grid variability in cloud (:math:`q_{cl}`) and
rain water (:math:`q_R`) to the autoconversion and accretion
parametrizations. :math:`f` is parametrized, either based on the
analysis of CloudSat, CloudNet-ARM and aircraft data presented in
:raw-latex:`\cite{boutle:etal:2014}` or for consistency set to the same
parametrization as used in the subgrid cloud generator that describes
subgrid cloud structure for the radiation scheme. The cloud-rain
correlation is specified, currently at :math:`\rho=0.9`.

Finally, the improved scheme includes a treatment of rain fraction
consistent with the prognostic rain formulation. Previously, rain
fraction was only created when cloud autoconverted or snow melted. With
prognostic rain, rain mass can be present in a column even if neither of
those processes has occurred, and can be advected between columns.
Therefore, if rain mass is present but rain fraction is not, the rain
fraction is set to the maximum cloud fraction in the column above. This
assumes that since the cloud fraction is prognostic, it will be advected
at approximately the same rate as the rain, and therefore is using the
cloud fraction as a proxy for the rain fraction rather than including an
additional prognostic variable.

.. _`sec:prog_precip_frac`:

Prognostic Precipitation Fraction
---------------------------------

Overview
~~~~~~~~

There is also an option to use an additional prognostic variable to
carry the rain fraction :math:`C_R`. This is enabled by turning on the
switch l_mcr_precfrac in the UM microphysics namelist. If this is used,
:math:`C_R` is preserved from one timestep to the next, and is advected
by the model winds, consistent with the rain mass.

If this is used, there is also an option to use the same prognostic
field to represent a sub-grid fraction for graupel (switch
l_subgrid_graupel_frac in the UM microphysics namelist). Otherwise,
graupel is assumed to be homgeneous across the whole grid-box.

The prognostic precipitation fraction is the STASH field 0,92: PRECIP
FRACTION IN EACH LAYER in the model dump, and has the variable name
:math:`precfrac` in the UM code.

When the same prognostic field is used for the fraction of both rain and
graupel, it is assumed that:

- Where :math:`q_R > 0` but :math:`q_{graup} = 0`, :math:`C_R` is just
  the rain fraction.

- Where :math:`q_R = 0` but :math:`q_{graup} > 0`, :math:`C_R` is just
  the graupel fraction.

- Where :math:`q_R > 0` and :math:`q_{graup} > 0`, rain and graupel are
  fully overlapped, so that they both have the same sub-grid fraction,
  given by :math:`C_R`.

(where :math:`q_R` and :math:`q_{graup}` are the mass mixing-ratios of
rain and graupel respectively).

Note: for riming onto graupel, turning on l_subgrid_graupel_frac also
fixes a bug in the calculation of riming of liquid-cloud onto graupel.
With this switched off, the riming calculation wrongly assumes that
graupel only exists within the ice-cloud partition.

Crucially, the prognostic approach for the precipitation fraction allows
a convection scheme to act as a source of rain and graupel at coarse
resolution. In this way, the microphysics code can be used to perform
the sedimentation and evaporation calculations for both “large-scale”
and convectively generated precipitaion consistently. If parameterised
convection is the primary source of rain or graupel mass, the
appropriate sub-grid fraction to use is the convective updraft fraction
at the height where the precipitation was produced, and this is likely
to be very different to the “large-scale” cloud fraction used in the
approach described in section `5.3 <#sec:warmnew>`__. With a prognostic
rain / graupel fraction, the convection scheme can update the fraction
alongside its update to :math:`q_R` and :math:`q_{graup}`, so that the
subsequent microphysics call uses the appropriate fraction for
convectively generated precipitation.

Effective fraction for inhomogeneous precipitation fields
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When using the prognostic precipitation fraction, the updating of the
rain fraction during each microphysics sub-step is modified.

The default behaviour (when not using the prognostic precipitation
fraction) is that, wherever rain is created, :math:`C_R` is reset to the
cloud-fraction in which the rain is produced if this is greater than the
existing value of :math:`C_R`. However, when allowing a convection
scheme to act as a source of rain, this was found to lead to excessive
evaporation of rain. In a coarse-resolution global model, often the
majority of the rain mass would be produced by the convection scheme,
with a small fractional area associated with intense convective cores. A
much smaller rain mass would be produced from diffuse large-scale cloud
with a much larger fractional area. But :math:`C_R` would be reset to
the large-scale cloud fraction, however small the proportion of
precipitation it contributed. This had the effect of forcing the
convective core rain to be spread over a much too large fractional area,
leading to underestimation of the fall-speeds / overestimation of the
rain evaporation. i.e. the extreme inhomogeneity of precipitation mass
in this situation is not adequately represented.

Therefore, when using the prognostic precipitation fraction, the
definition of :math:`C_R` is amended. Rather than representing the
fraction of the grid-box containing non-zero rain-mass (which is
actually hard to define or measure, since the edges of rain-shafts can
be very diffuse), it is used as a representative fraction such that the
in-rain-shaft precipitation mixing-ratio :math:`\frac{q_p}{C_R}` used in
the process-rate calculations will reflect the precip mixing-ratio
likely to be found in the part of the rain-shaft where most of the rain
/ graupel mass is located (:math:`q_p = q_R + q_{graup}` if prognosing a
single fraction for both rain and graupel, otherwise :math:`q_p = q_R`).
We therefore define :math:`C_R` such that:

.. math::

   \frac{\overline{q_p}}{C_R}
   = \frac{\overline{q_p \; q_p}}{\overline{q_p}}

(where the overbar denotes a grid-box-mean). The r.h.s. is just the
precip-mass-weighted mean value of :math:`q_p`, which gives us a
representative value of :math:`q_p` where precip-mass is present.
Rearranging:

.. math::

   \label{eq:representative_c_r}
   C_R = \frac{ \overline{q_p}^2 }{ \overline{q_p^2} }

Two different options have been implemented for how to update this
quantity consistently when incrementing the precip mass due to
microphysical process rates, sedimentation and numerical checks. These
are decribed in the following sections below. The method to use is
selected using the switch i_update_precfrac in the UM namelist.

|  

Assume homogeneous precip mass within the precip fraction at start-of-timestep
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Under this option (selected by setting i_update_precfrac = 1), the
precipitation mass is assumed to be homogeneous *within* the
area-fraction :math:`C_r` at the start of each timestep. Various
processes can change the precip mass within some parts of the region
:math:`C_r` but not others (or add new precip mass outside of the
start-of-timestep :math:`C_r`, so that :math:`C_r` is increased), thus
creating inhomogeneity within :math:`C_r` during the timestep. But at
the end of every timestep :math:`C_r` is recalculated following eq
(`[eq:representative_c_r] <#eq:representative_c_r>`__) and then assumed
to reset to having homogeneous precip mass within that area.

.. _`sec:precip_frac_update`:

Update of precipitation fraction by process-rates
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

|  
| During each microphysics sub-step, the net rain (and optionally
  graupel) mass increment within each of the following 5 sub-grid
  partitions is calculated and stored:

- **rain_liq**: area containing both liquid-only cloud and rain (and/or
  graupel) at the start of the current microphysics sub-step.

- **rain_mix**: area containing both mixed-phase cloud and rain (and/or
  graupel) at the start of the current microphysics sub-step.

- **rain_ice**: area containing both ice-only cloud and rain (and/or
  graupel) at the start of the current microphysics sub-step.

- **rain_clear**: area containing rain (and/or graupel) in cloud-free
  air at the start of the current microphysics sub-step.

- **rain_new**: area where rain (and/or graupel) is produced where there
  wasn’t any at the start of the current microphysics sub-step.

(where the areas of the first 4 of these sum to the start-of-timestep
:math:`C_r`).

Table `11 <#tab:precfrac_processes>`__ summarises which of these
sub-grid partitions each microphysical process rate affecting rain and
graupel mass is assumed to act within.

.. container:: center

   .. container::
      :name: tab:precfrac_processes

      .. table:: Processes affecting precipitation mass within the
      sub-grid precipitation fraction area partitions, when using
      i_update_precfrac = 1. “+” signs denote sources of preipitation
      mass, whereas “-” signs denote sinks.

         +----------+----------+----------+----------+----------+----------+
         |          | **ra     | **ra     | **ra     | **rain   | **ra     |
         |          | in_liq** | in_mix** | in_ice** | _clear** | in_new** |
         +==========+==========+==========+==========+==========+==========+
         | PRACW    | +        | +        |          |          |          |
         | (a       |          |          |          |          |          |
         | ccretion |          |          |          |          |          |
         | of       |          |          |          |          |          |
         | liqu     |          |          |          |          |          |
         | id-cloud |          |          |          |          |          |
         | by rain) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PRAUT    | +        | +        |          |          | +        |
         | (autoco  |          |          |          |          |          |
         | nversion |          |          |          |          |          |
         | of       |          |          |          |          |          |
         | liqu     |          |          |          |          |          |
         | id-cloud |          |          |          |          |          |
         | to rain) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PIP      | -        | -        | -        | -        | -        |
         | RR,PIFRR |          |          |          |          |          |
         | (        |          |          |          |          |          |
         | freezing |          |          |          |          |          |
         | of rain) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PGACW    | +        | +        |          |          |          |
         | (riming  |          |          |          |          |          |
         | of       |          |          |          |          |          |
         | liqu     |          |          |          |          |          |
         | id-cloud |          |          |          |          |          |
         | onto     |          |          |          |          |          |
         | graupel) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PSA      |          | -        | -        |          |          |
         | CR,PIACR |          |          |          |          |          |
         | (capture |          |          |          |          |          |
         | of rain  |          |          |          |          |          |
         | by       |          |          |          |          |          |
         | ic       |          |          |          |          |          |
         | e-cloud) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PGAUT    |          | +        |          |          | +        |
         | (autoco  |          |          |          |          |          |
         | nversion |          |          |          |          |          |
         | of snow  |          |          |          |          |          |
         | to       |          |          |          |          |          |
         | graupel) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PGACS    |          | +        | +        |          |          |
         | (co      |          |          |          |          |          |
         | llection |          |          |          |          |          |
         | of       |          |          |          |          |          |
         | i        |          |          |          |          |          |
         | ce-cloud |          |          |          |          |          |
         | by       |          |          |          |          |          |
         | graupel) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PSM      |          | +        | +        |          | +        |
         | LT,PIMLT |          |          |          |          |          |
         | (melting |          |          |          |          |          |
         | of       |          |          |          |          |          |
         | i        |          |          |          |          |          |
         | ce-cloud |          |          |          |          |          |
         | into     |          |          |          |          |          |
         | rain)    |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+
         | PREVP    |          |          | -        | -        |          |
         | (eva     |          |          |          |          |          |
         | poration |          |          |          |          |          |
         | of rain) |          |          |          |          |          |
         +----------+----------+----------+----------+----------+----------+

Note that collisions between ice-cloud and rain (PSACR,PIACR) are a sink
of precipitation mass if the rain is converted into ice-cloud, but this
sink goes to zero if options are set to convert the collided rain into
graupel (and include graupel in the “precipitation” fraction).

Also note that if using the option to produce accretion and riming from
orographically-forced clouds, via the “seeder feeder” mechanism (see
section `8 <#sec:seeder_feeder>`__), the rainy liquid cloud fraction
used for this maybe considerably larger than the areas **rain_liq** +
**rain_mix**, due to the temporarily-assumed additional liquid-cloud
forced by sub-grid-scale orography. When this occurs, any source of rain
from the seeder-feeder scheme occuring beyond the area **rain_liq** +
**rain_mix** is assumed to occur in the **rain_new** partition.

At the end of each microphysics sub-step, :math:`C_R` is updated as
follows. First, the local in-partition values of precipitation
mixing-ratio at the end of the sub-step are calculated for each sub-grid
partition:

.. math:: {q_p}_{liq} = \frac{{q_p}_n}{{C_R}_n} + \frac{d{q_p}_{liq}}{rain\_liq}

.. math:: {q_p}_{mix} = \frac{{q_p}_n}{{C_R}_n} + \frac{d{q_p}_{mix}}{rain\_mix}

.. math:: {q_p}_{ice} = \frac{{q_p}_n}{{C_R}_n} + \frac{d{q_p}_{ice}}{rain\_ice}

.. math:: {q_p}_{clear} = \frac{{q_p}_n}{{C_R}_n} + \frac{d{q_p}_{clear}}{rain\_clear}

.. math:: {q_p}_{new} = \frac{d{q_p}_{new}}{rain\_new}

where :math:`{q_p}` denotes :math:`q_R + q_{graup}` if
l_subgrid_graupel_frac is on, or just :math:`q_R` otherwise, and
:math:`d{q_p}` are the stored increments to :math:`{q_p}` within each of
the 5 partitions. Note we have assumed that any precipitation mass
present at the start of the current sub-step is distributed evenly
across all the partitions except for **rain_new**. The new value of
:math:`C_R` is then given by equation
`[eq:representative_c_r] <#eq:representative_c_r>`__, expanding out the
grid-means in the numerator and denominator:

.. math::

   {C_R}_{n+1} = \frac{ \left( rain\_liq \; {q_p}_{liq} + rain\_mix \; {q_p}_{mix}
                            + rain\_ice \; {q_p}_{ice} + rain\_clear \; {q_p}_{clear}
                            + rain\_new \; {q_p}_{new} \right)^2 }
                    { rain\_liq \; {q_p}_{liq}^2 + rain\_mix \; {q_p}_{mix}^2
                    + rain\_ice \; {q_p}_{ice}^2 + rain\_clear \; {q_p}_{clear}^2
                    + rain\_new \; {q_p}_{new}^2 }

This calculation is done in subroutine lsp_update_precfrac in the code.

.. _`sec:precfrac_sed`:

Transfer of precipitation fraction by sedimentation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

|  
| For numerics reasons, the updating of precipitation fraction by fall
  of precipitation is handled separately to the other microphysical
  processes.

While the prognostic precipitation fraction stores the fraction occupied
by rain and/or graupel at the model theta-levels, we use a separate
temporary field to store the fraction of rain and/or graupel that falls
through the model-level interfaces, from one theta-level down to the
next (called precfrac_fall in the code). This is needed, because it is
possible for all rain on the current theta-level at the end of the
microphysics sub-step to evaporate, but still have some rain falling
through to the next level down during that sub-step. In this case, rain
fraction at theta-level k should be reset to zero, but the rain fraction
passed down to the next level should not.

Where sedimentation of rain and/or graupel is calculated, we will have:

- Pre-existing values of precipitation mass and fraction at theta-level
  k, :math:`{q_p}_k` and :math:`{C_R}_k`.

- Mass and fraction of precipitation falling into theta-level k from
  above, :math:`{q_p}_{fall} = \frac{\Delta t}{\rho \Delta z} P` and
  :math:`{C_R}_{fall}`.

where :math:`P` denotes the rain-rate plus the graupel fall-flux if
l_subgrid_graupel_frac is on, or just the rain-rate otherwise.

The combined effective precipitation fraction :math:`{C_R}_{combined}`
resulting from merging the falling-in precipitation
:math:`{q_p}_{fall}`, :math:`{C_R}_{fall}` with the existing
precipitation :math:`{q_p}_k`, :math:`{C_R}_k` is calculated using
equation `[eq:representative_c_r] <#eq:representative_c_r>`__, assuming
the fractions :math:`{C_R}_k` and :math:`{C_R}_{fall}` are maximally
overlapped.

If :math:`{C_R}_{fall} > {C_R}_k`, then we will end up with 2
partitions:

- Fraction :math:`{C_R}_k` containing precipitation mass
  :math:`\frac{{q_p}_k}{{C_R}_k} + \frac{{q_p}_{fall}}{{C_R}_{fall}}`
  (contributions from both existing and falling-in precipitation mass).

- Fraction :math:`{C_R}_{fall} - {C_R}_k` containing precipitation mass
  :math:`\frac{{q_p}_{fall}}{{C_R}_{fall}}` (contribution from only
  falling-in precipitation mass).

From equation `[eq:representative_c_r] <#eq:representative_c_r>`__,
expanding out the grid-means in the numerator and denominator over these
2 regions, the combined precipitation fraction will then be:

.. math::

   {C_R}_{combined} = \frac{ \left( {C_R}_k \left( \frac{{q_p}_k}{{C_R}_k}
                                              + \frac{{q_p}_{fall}}{{C_R}_{fall}}
                                         \right)
                               + \left( {C_R}_{fall} - {C_R}_k \right)
                                 \frac{{q_p}_{fall}}{{C_R}_{fall}} \right)^2 }
                        { {C_R}_k \left( \frac{{q_p}_k}{{C_R}_k}
                                      + \frac{{q_p}_{fall}}{{C_R}_{fall}}
                                         \right)^2
                               + \left( {C_R}_{fall} - {C_R}_k \right)
                                 \left( \frac{{q_p}_{fall}}{{C_R}_{fall}} \right)^2 }

This rearranges to give:

.. math::

   \label{eq:combine_cr}
   {C_R}_{combined} = \frac{ {C_R}_k {C_R}_{fall} }
                         { {C_R}_k + \left( {C_R}_{fall} - {C_R}_k \right)
                           \left( \frac{{q_p}_k}{{q_p}_k + {q_p}_{fall}} \right)^2 }

If instead :math:`{C_R}_{fall} < {C_R}_k`, by symmetry the result is
exactly the same but with the labels “:math:`_k`” and
“\ :math:`_{fall}`" swapped. This calculation is done in subroutine
lsp_combine_precfrac in the code.

.. _`sec:precfrac:emerg`:

Precipitation fraction created by “emergency melting”
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

|  
| As described in section `7.4 <#sec:num_check>`__, after the
  microphysical processes at theta-level k have been computed, and
  sedimentation of hydrometeors down to the next level has been
  calculated, an additional “emergency melting” term is applied which
  can convert the snowfall flux :math:`S` down to the next level into
  rain. This requires an additional update to the precipitation
  fraction, to keep it consistent with the rain.

By default, “emergency melting” converts the snow flux :math:`S` into
rain mass :math:`q_R` on the current theta-level k. However, the
implementation of the prognostic precipitation fraction is simpler if
this melting term converts snow flux :math:`S` into rain flux :math:`R`
(this is also more intuitive; the default conversion arbitrarily
“un-sediments” the melting snow flux back onto level k). Therefore, when
using the prognostic precipitation fraction, “emergency melting”
converts the melted snow flux :math:`S` into rain flux :math:`R`, and
correspondingly updates the falling-out precipitation fraction
:math:`{C_R}_{fall}` passed down to the next level, whilst leaving
:math:`q_R` and :math:`{C_R}_k` unchanged.

Following the same argument as for sedimentation above, the combined
precipitation fraction produced by the combination of existing
precipitation flux :math:`P` (with fraction :math:`{C_R}_{fall}`) and
melted snow flux :math:`dS_{melt}` (with fraction :math:`{C_i}_{fall}`)
is given by:

For :math:`{C_R}_{fall} > {C_i}_{fall}`,

.. math::

   {C_R}_{fall \; combined} = \frac{ {C_i}_{fall} {C_R}_{fall} }
                         { {C_i}_{fall} + \left( {C_R}_{fall} - {C_i}_{fall} \right)
                           \left( \frac{dS_{melt}}{P + dS_{melt}} \right)^2 }

And for :math:`{C_R}_{fall} < {C_i}_{fall}`, the formula is the same but
with :math:`{C_i}_{fall}`, :math:`dS_{melt}` and :math:`{C_R}_{fall}`,
:math:`P` swapped.

And finally...
^^^^^^^^^^^^^^

|  
| After the updates to the prognostic precipitation fraction from all
  the processes discussed above, a final check (in lsp_tidy.F90) resets
  the precipitation fraction to zero in the event that all rain (and
  optionally graupel) mass has been removed.

|  

Inhomogeneous precip mass with parameterised sub-grid correlations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Under this option (selected by setting i_update_precfrac = 2), we remove
the assumption that precipitation mass returns to being homogeneous
within the area :math:`C_r` at the end of each timestep. It was found
that this assumption led to a spurious timestep sensitivity (the shorter
the timestep, the more frequent the assumed return to homogeneity, and
this systematically alters the solution over time). To illustrate the
problem mathematically, consider eq
(`[eq:combine_cr] <#eq:combine_cr>`__) but for the case where
:math:`{C_R}_{fall} < {C_R}_k`, substituting
:math:`{q_P}_{fall} = \frac{\Delta t}{\rho \Delta z} P`, and rearrange
to obtain an expression for the tendency in :math:`C_R` for a given
fall-flux of precipitation :math:`P`:

.. math::

   \begin{aligned}
   \frac{ {{C_R}_k}_{n+1} - {{C_R}_k}_n }{\Delta t}
    & \; = \; \frac{1}{\Delta t} \left(
                    \frac{ {C_R}_{fall} {{C_R}_k}_n }
                         { {C_R}_{fall} + \left( {{C_R}_k}_n - {C_R}_{fall} \right)
                       \left( \frac{ \frac{\Delta t}{\rho \Delta z} P }
                                   { \frac{\Delta t}{\rho \Delta z} P + {q_p}_k }
                       \right)^2 }
                   - {{C_R}_k}_n \right)
   \nonumber \\
    & \; = \; \frac{{{C_R}_k}_n}{\Delta t} \left(
                    \frac{ 1 }
                         { 1 + \left( \frac{{{C_R}_k}_n}{{C_R}_{fall}} - 1 \right)
                       \left(
                  \frac{     \frac{\Delta t}{\rho \Delta z} \frac{P}{{q_p}_k} }
                       { 1 + \frac{\Delta t}{\rho \Delta z} \frac{P}{{q_p}_k} }
                       \right)^2 }
                                      - 1 \right)
   \nonumber
   \end{aligned}

Now take the limit of small :math:`\Delta t` to express this in terms of
continuous calculus:

.. math::

   \begin{aligned}
   \frac{ \partial {C_R}_k }{ \partial t}
    & \; = \; \frac{{C_R}_k}{\Delta t} \left(
                    \frac{ 1 }
                         { 1 + \left( \frac{{C_R}_k}{{C_R}_{fall}} - 1 \right)
               \left( \frac{\Delta t}{\rho \Delta z} \frac{P}{{q_p}_k} \right)^2 }
                                      - 1 \right)
   \nonumber \\
    & \; = \; \frac{{C_R}_k}{\Delta t} \left(
                   1 - \left( \frac{{C_R}_k}{{C_R}_{fall}} - 1 \right)
               \left( \frac{\Delta t}{\rho \Delta z} \frac{P}{{q_p}_k} \right)^2
                                      - 1 \right)
   \nonumber \\
    & \; = \; - {C_R}_k \left( \frac{{C_R}_k}{{C_R}_{fall}} - 1 \right)
               \left( \frac{1}{\rho \Delta z} \frac{P}{{q_p}_k} \right)^2
               \Delta t
   \nonumber
   \end{aligned}

The tendency scales with :math:`\Delta t` and therefore goes to zero in
the limit of small timesteps. i.e. eq
(`[eq:combine_cr] <#eq:combine_cr>`__) does not converge to the solution
to any reasonable continuous differential equation for :math:`C_R`. In
the limit of small :math:`\Delta t`, it is impossible for precip mass
being injected by a process with a small area-fraction to reduce any
pre-existing larger :math:`C_R` (however small the pre-existing precip
mass associated with it). This leads to a problem with strong
sensitivity to timestep and over-persistence of large values of
:math:`C_R` when using the original method (i_update_precfrac = 1).

Under the new method (i_update_precfrac = 2), we take care to ensure the
formulae used actually converge to sensible solutions with reducing
timestep. Instead of assuming re-homogenisation of precip mass within
:math:`C_R` once per timestep, we compute separate increments to
:math:`C_r` from each process which modifies precip mass. This requires
parameterising the sub-grid spatial correlation between each process’s
precip mass tendency and the existing precip mass...

Update of precipitation fraction from precip mass sources
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

|  
| Following our definition of
  :math:`C_r = \frac{ \overline{q_p}^2 }{ \overline{q_p^2} }` (eq
  `[eq:representative_c_r] <#eq:representative_c_r>`__), the updated
  value of :math:`C_r` following each increment to grid-mean precip mass
  :math:`\overline{q_p}` can be calculated if we also know the
  corresponding increment to the 2nd moment of the sub-grid precip-mass
  spatial-distribution :math:`\overline{q_p^2}`.

For the first moment, we have:

.. math::

   \begin{aligned}
   \overline{{q_p}_{n+1}}
    & \;= \; \overline{ {q_p}_n + \frac{\partial q_p}{\partial t} \Delta t }
   \nonumber \\
    & \; = \; \overline{ {q_p}_n }
      \; + \; \overline{ \frac{\partial q_p}{\partial t} } \; \Delta t
   \label{eq:q_p_np1}
   \end{aligned}

where :math:`{q_p}_n` is the precip mass before the process,
:math:`\frac{\partial q_p}{\partial t}` is the spatially-varying precip
mass tendency, :math:`{q_p}_{n+1}` is the precip mass after the process,
and :math:`\Delta t` is the microphysics timestep length.

For the 2nd moment:

.. math::

   \begin{aligned}
   \overline{{q_p}_{n+1}^2}
    & \; = \; \overline{ \left( {q_p}_n + \frac{\partial q_p}{\partial t} \Delta t
                  \right)^2 }
   \nonumber \\
    & \; = \; \overline{ {q_p}_n^2 }
      \; + \; 2 \; \overline{ {q_p}_n \frac{\partial q_p}{\partial t} } \; \Delta t
      \; + \; \overline{ \frac{\partial q_p}{\partial t}^2 } \; \Delta t^2
   \label{eq:q_p_np1_sq_1}
   \end{aligned}

Rearranging our definition of :math:`C_R`
(`[eq:representative_c_r] <#eq:representative_c_r>`__), we have:

.. math::

   \label{eq:qpn_sq}
   \overline{ {q_p}_n^2 } = \frac{ \overline{{q_p}_n}^2 }{ {C_R}_n }

And we can similarly write:

.. math::

   \label{eq:dqpdt_sq}
   \overline{ \frac{\partial q_p}{\partial t}^2 }
    = \frac{ \overline{\frac{\partial q_p}{\partial t}}^2 }{ C_{proc} }

where :math:`C_{proc}` is the area-fraction where the precip-mass
tendency takes place (e.g. for accretion, :math:`C_{proc}` is the area
of overlap between rain and liquid-cloud).

The cross term
:math:`\overline{ {q_p}_n \frac{\partial q_p}{\partial t} }` on the
r.h.s. of (`[eq:q_p_np1_sq_1] <#eq:q_p_np1_sq_1>`__) depends on the
sub-grid spatial correlation between the existing precip mass and the
process-rate tendency.

In the limit that :math:`{q_p}_n` and
:math:`\frac{\partial q_p}{\partial t}` are independent / randomly
overlapped, there is zero spatial correlation so that:

.. math::

   \overline{ {q_p}_n \frac{\partial q_p}{\partial t} }
    \; = \; \overline{ {q_p}_n } \overline{ \frac{\partial q_p}{\partial t} }

However, for most processes there is likely to be significant spatial
correlation of the precip tendency field with the existing precip mass,
so that this would not be a realistic choice. For example, increase of
rain-mass by accretion of cloud-water onto rain-drops will be skewed
towards areas which already have a high density of fast-falling rain,
while rain-mass is likely to be higher in regions of the grid-box where
rain is currently being produced by autoconversion or melting of snow.

Instead, we assume :math:`{q_p}_n` and
:math:`\frac{\partial q_p}{\partial t}` are highly correlated, such that
the spatial mean of their product equals the product of their in-area
values, converted to a grid-mean by scaling by a representative average
area-fraction for the two fields, taken to be the geometric mean of
:math:`{C_R}_n` and :math:`C_{proc}`:

.. math::

   \begin{aligned}
   \overline{ {q_p}_n \frac{\partial q_p}{\partial t} }
    & \; = \; \frac{ \overline{ {q_p}_n } }{ {C_R}_n } \;
              \frac{ \overline{ \frac{\partial q_p}{\partial t} } }{ C_{proc} } \;
              \sqrt{ {C_R}_n C_{proc} }
   \nonumber \\
    & \; = \; \frac{ \overline{ {q_p}_n } \;
                     \overline{ \frac{\partial q_p}{\partial t} } }
                   { \sqrt{ {C_R}_n C_{proc} } }
   \label{eq:cross_term_correl} \\
    & \; = \; \sqrt{ \overline{ {q_p}_n^2 } \;
                     \overline{ \frac{\partial q_p}{\partial t}^2 } }
   \nonumber
   \end{aligned}

The last line above is derived by noting that
(`[eq:cross_term_correl] <#eq:cross_term_correl>`__) is the product of
the square-roots of (`[eq:qpn_sq] <#eq:qpn_sq>`__) and
(`[eq:dqpdt_sq] <#eq:dqpdt_sq>`__).

Substituting (`[eq:qpn_sq] <#eq:qpn_sq>`__),
(`[eq:dqpdt_sq] <#eq:dqpdt_sq>`__) and
(`[eq:cross_term_correl] <#eq:cross_term_correl>`__) into
(`[eq:q_p_np1_sq_1] <#eq:q_p_np1_sq_1>`__), we obtain:

.. math::

   \begin{aligned}
   \overline{{q_p}_{n+1}^2}
   & \; = \; \frac{ \overline{{q_p}_n}^2 }{ {C_R}_n }
      \; + \; 2 \; \frac{ \overline{ {q_p}_n } \;
                          \overline{ \frac{\partial q_p}{\partial t} } }
                        { \sqrt{ {C_R}_n C_{proc} } } \; \Delta t
      \; + \; \frac{ \overline{\frac{\partial q_p}{\partial t}}^2 }{ C_{proc} }
           \; \Delta t^2
   \nonumber \\
   & \; = \; \left( \frac{ \overline{{q_p}_n} }{ \sqrt{ {C_R}_n } }
             \; + \; \frac{ \overline{\frac{\partial q_p}{\partial t}} }
                          { \sqrt{ C_{proc} } } \; \Delta t
             \right)^2
   \label{eq:q_p_np1_sq_2}
   \end{aligned}

Now substituting (`[eq:q_p_np1] <#eq:q_p_np1>`__) for
:math:`\overline{{q_p}_{n+1}}` and
(`[eq:q_p_np1_sq_2] <#eq:q_p_np1_sq_2>`__) for
:math:`\overline{{q_p}_{n+1}^2}` into our equation
(`[eq:representative_c_r] <#eq:representative_c_r>`__) for the updated
:math:`C_R`, we obtain our formula for updating the prognostic precip
fraction wherever precipitation mass is produced:

.. math::

   \label{eq:cr_np1}
   {C_R}_{n+1} \; = \;
     \frac{ \overline{{q_p}_{n+1}}^2 }{ \overline{{q_p}_{n+1}^2} }
   \; = \;
     \frac{ \left( \overline{ {q_p}_n }
           \; + \; \overline{ \frac{\partial q_p}{\partial t} } \; \Delta t
            \right)^2 }
          { \left( \frac{ \overline{{q_p}_n} }{ \sqrt{ {C_R}_n } }
             \; + \; \frac{ \overline{\frac{\partial q_p}{\partial t}} }
                          { \sqrt{ C_{proc} } } \; \Delta t
             \right)^2 }

Note this is equivalent to setting :math:`\frac{1}{\sqrt{C_R}}` to the
precip-mass-weighted mean over its values from all contributing
mass-sources:

.. math::

   \frac{1}{\sqrt{{C_R}_{n+1}}} \; = \;
     \frac{ \overline{{q_p}_n} \frac{1}{\sqrt{{C_R}_n}} \; + \;
            \overline{\frac{\partial q_p}{\partial t}} \Delta t
                              \frac{1}{\sqrt{C_{proc}}} }
          { \overline{{q_p}_n} \; + \;
            \overline{\frac{\partial q_p}{\partial t}} \Delta t }

This method should be insensitive to timestep-length :math:`\Delta t`,
since a mass-weighted mean of any quantity is the same regardless of how
many timesteps the total increment is split into.

Taking 1st order Taylor expansions in the limit of small
:math:`\Delta t`, we can also write (`[eq:cr_np1] <#eq:cr_np1>`__) as a
continuous differential equation for :math:`C_R`:

.. math::

   \begin{aligned}
   \frac{\partial C_R}{\partial t}
   & \; = \;
   \frac{1}{\Delta t} \left(
     \frac{ \left( \overline{ q_p }
           \; + \; \overline{ \frac{\partial q_p}{\partial t} } \; \Delta t
            \right)^2 }
          { \left( \frac{ \overline{q_p} }{ \sqrt{ C_R } }
             \; + \; \frac{ \overline{\frac{\partial q_p}{\partial t}} }
                          { \sqrt{ C_{proc} } } \; \Delta t
             \right)^2 }
    \; - \; C_R \right)
   \nonumber \\
   & \; = \;
   \frac{1}{\Delta t} \left(
     \frac{ \overline{ q_p }^2 \left( 1
           \; + \; 2 \frac{1}{\overline{ q_p }}
                     \overline{ \frac{\partial q_p}{\partial t} } \; \Delta t
            \right) }
          { \frac{ \overline{q_p}^2 }{ C_R } \left( 1
             \; + \; 2 \frac{ \sqrt{ C_R } }{ \overline{q_p} }
                       \frac{ \overline{\frac{\partial q_p}{\partial t}} }
                            { \sqrt{ C_{proc} } } \; \Delta t
             \right) }
    \; - \; C_R \right)
   \nonumber \\
   & \; = \;
   \frac{C_R}{\Delta t} \left(
     \left( 1 \; + \; 2 \frac{1}{\overline{ q_p }}
                        \overline{ \frac{\partial q_p}{\partial t} } \; \Delta t
     \right)
     \left( 1 \; - \; 2 \frac{ \sqrt{ C_R } }{ \overline{q_p} }
                        \frac{ \overline{\frac{\partial q_p}{\partial t}} }
                             { \sqrt{ C_{proc} } } \; \Delta t
     \right)
    \; - \; 1 \right)
   \nonumber \\
   & \; = \;
   \frac{C_R}{\Delta t} \left(
     \left( 1 \; + \; 2 \frac{1}{\overline{ q_p }}
                        \overline{ \frac{\partial q_p}{\partial t} } \; \Delta t
                        \left( 1 - \sqrt{\frac{ C_R }{ C_{proc} }} \right)
     \right)
    \; - \; 1 \right)
   \nonumber \\
   & \; = \; 2 \frac{C_R}{\overline{ q_p }}
             \overline{ \frac{\partial q_p}{\partial t} }
             \left( 1 - \sqrt{\frac{ C_R }{ C_{proc} }} \right)
   \label{eq:dcr_dt}
   \end{aligned}

However it is important that we use the time-integrated solution
(`[eq:cr_np1] <#eq:cr_np1>`__) instead of attempting a forwards-time
discretisation of (`[eq:dcr_dt] <#eq:dcr_dt>`__), in order to correctly
integrate over the singularity when :math:`C_R = q_p = 0`.

Table `12 <#tab:precfrac_processes_2>`__ lists the processes where
(`[eq:cr_np1] <#eq:cr_np1>`__) is applied to update :math:`C_R`
consistent with source terms for :math:`q_p`, and what area-fraction
:math:`C_{proc}` is assumed for the tendency
:math:`\frac{\partial q_p}{\partial t}` from each process.

If using the option to produce accretion and riming from
orographically-forced clouds, via the “seeder feeder” mechanism (see
section `8 <#sec:seeder_feeder>`__), the rainy liquid cloud fraction
used for this maybe considerably larger than the areas **rain_liq** +
**rain_mix**, due to the temporarily-assumed additional liquid-cloud
forced by sub-grid-scale orography. When this occurs, :math:`C_{proc}`
is set to the already-calculated area of overlap between
orographically-forced liquid-cloud and rain.

Update of precipitation fraction from precip mass sinks
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

|  
| Firstly, we assume that the sink of precip mass from freezing of rain
  (PIPRR, PIFRR) applies uniformly over the sub-grid precip mass
  distribution, so that :math:`C_R` is not affected by this process
  (except in the case where the rain mass is removed completely so that
  :math:`C_R` is reset to zero).

For the sink of rain via capture by ice-cloud (PSACR, PIACR), in the
limit that the rain is fully overlapped with ice-cloud, we similarly
assume removal of rain occurs uniformly such that :math:`C_R` is not
affected. However, if the rain-fraction :math:`C_R` only partially
overlaps with the capturing ice (**rain_ice** + **rain_mix**
:math:`< C_R`) then the removal of rain within only the ice part of its
area is expected to enhance the sub-grid inhomogeneity of :math:`q_R`
and so reduce :math:`C_R`. For the timebeing, a smooth behaviour between
these limits is parameterised as:

.. math::

   \label{eq:dcr_capture}
   \frac{\partial C_R}{\partial t} = \left( C_R - rain\_ice - rain\_mix \right)
     \frac{1}{\overline{q_p}}
     \; \overline{ \frac{\partial q_p}{\partial t} }

where :math:`q_p = q_R + q_{graup}` if prognosing a single fraction for
both rain and graupel, otherwise :math:`q_p = q_R`. Note that this
process can convert :math:`q_R` to either the capturing ice-cloud mass
or to graupel mass, depending on options and conditions. If prognosing a
single fraction for both rain and graupel,
:math:`\frac{\partial q_p}{\partial t}` in
(`[eq:dcr_capture] <#eq:dcr_capture>`__) is (minus) the rate of
conversion of rain to ice-cloud only, since the conversion of rain to
graupel does not change :math:`q_p`.

For the sink of rain via evaporation (PREVP), we do not wish to assume
that precip is removed uniformly over the sub-grid spatial distribution
of :math:`q_p`, even when the whole of the distribution is below
saturation. This is because regions of the distribution with smaller
rain-mass tend to carry smaller rain-drops, so that the fractional rate
of evaporation is higher. Therefore evaporation rate does not scale
linearly with :math:`q_p`; regions on the edge of the rain-shaft can
evaporate away completely while other parts of the rainshaft do not, so
that :math:`C_R` is reduced by rain evaporation. This is parameterised
as:

.. math::

   \label{eq:dcr_evap}
   \frac{\partial C_R}{\partial t} = \frac{1}{2} C_R
     \frac{1}{\overline{q_p}} \overline{ \frac{\partial q_p}{\partial t} }

where :math:`\frac{\partial q_p}{\partial t}` is the rate of change of
grid-mean rain mixing-ratio due to rain evaporation (note this is always
negative, hence so is :math:`\tfrac{\partial C_R}{\partial t}` for this
process). i.e. the fractional rate of reduction of :math:`C_R` is half
the fractional rate of reduction of :math:`q_p`, so that over time
evaporation reduces :math:`C_R` in proportion to the square-root of
rain-mass. From (`[eq:representative_c_r] <#eq:representative_c_r>`__),
this is equivalent to assuming that evaporation reduces the 2nd moment
of the sub-grid spatial distribution :math:`\overline{q_p^2}` in
proportion with the first moment :math:`\overline{q_p}` raised to the
power :math:`\tfrac{3}{2}`.

We time-integrate (`[eq:dcr_evap] <#eq:dcr_evap>`__) separately in the
saturated (liquid-cloud) and subsaturated sub-regions of :math:`C_R`,
assuming (consistent with the rest of the rain evaporation code) that
evaporation takes place only outside the liquid-cloud:

.. math::

   \begin{aligned}
   {C_R}_{n+1}
   & \; = \; \left( 1 - \frac{rain\_ice + rain\_clear}{C_R} \right) {C_R}_n
   \nonumber \\
   & \; + \; \frac{rain\_ice + rain\_clear}{C_R} {C_R}_n
                \sqrt{ 1 + \frac{C_R}{rain\_ice + rain\_clear}
                           \frac{1}{\overline{q_p}}
                           \overline{\frac{\partial q_p}{\partial t}} \Delta t }
   \nonumber
   \end{aligned}

where :math:`\Delta t` is the microphysics timestep length. Note that in
the limit of small :math:`\Delta t`, taking a 1st order Taylor expansion
of the square-root term, all of the factors of
:math:`\frac{C_R}{rain\_ice + rain\_clear}` cancel and we retreive
(`[eq:dcr_evap] <#eq:dcr_evap>`__).

.. container:: center

   .. container::
      :name: tab:precfrac_processes_2

      .. table:: Method, equation and process-fraction :math:`C_{proc}`
      used to update the prognostic precipitation fraction consistent
      with precip mass for each process, when using i_update_precfrac =
      2.

         +----------------+----------------+----------------+----------------+
         |                | Source(+) or   | Eqn for        | **:mat         |
         |                | sink(-)        | :math:`C_R`    | h:`C_{proc}`** |
         |                |                | update         |                |
         +================+================+================+================+
         | PRACW          | +              | (`             | **rain_liq** + |
         | (accretion of  |                | [eq:cr_np1] <# | **rain_mix**   |
         | liquid-cloud   |                | eq:cr_np1>`__) |                |
         | by rain)       |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PRAUT          | +              | (`             | :math:`C_l`    |
         | (              |                | [eq:cr_np1] <# |                |
         | autoconversion |                | eq:cr_np1>`__) |                |
         | of             |                |                |                |
         | liquid-cloud   |                |                |                |
         | to rain)       |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PIPRR,PIFRR    | -              | Not updated    | None           |
         | (freezing of   |                |                |                |
         | rain)          |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PGACW (riming  | +              | (`             | **rain_liq** + |
         | of             |                | [eq:cr_np1] <# | **rain_mix**   |
         | liquid-cloud   |                | eq:cr_np1>`__) |                |
         | onto graupel)  |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PSACR,PIACR    | -              | (`[eq:dcr_ca   | **rain_ice** + |
         | (capture of    |                | pture] <#eq:dc | **rain_mix**   |
         | rain by        |                | r_capture>`__) |                |
         | ice-cloud)     |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PGAUT          | +              | (`             | :math:`C_      |
         | (              |                | [eq:cr_np1] <# | {mixed~phase}` |
         | autoconversion |                | eq:cr_np1>`__) |                |
         | of ice-cloud   |                |                |                |
         | to graupel)    |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PGACS          | +              | (`             | **rain_ice** + |
         | (collection of |                | [eq:cr_np1] <# | **rain_mix**   |
         | ice-cloud by   |                | eq:cr_np1>`__) |                |
         | graupel)       |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PSMLT,PIMLT    | +              | (`             | :math:`C_i`    |
         | (melting of    |                | [eq:cr_np1] <# |                |
         | ice-cloud into |                | eq:cr_np1>`__) |                |
         | rain)          |                |                |                |
         +----------------+----------------+----------------+----------------+
         | PREVP          | -              | (`[eq:         | **rain_ice** + |
         | (evaporation   |                | dcr_evap] <#eq | **rain_clear** |
         | of rain)       |                | :dcr_evap>`__) |                |
         +----------------+----------------+----------------+----------------+

Transfer of precipitation fraction by sedimentation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

|  
| This follows the same method as described for i_update_precfrac = 1 in
  section `5.4.3.2 <#sec:precfrac_sed>`__, except that we now use eq
  (`[eq:cr_np1] <#eq:cr_np1>`__) for combining the pre-existing and
  falling-in precip masses assuming both have strongly-correlated
  sub-grid spatial distributions. The tendency from fall-in of precip
  mass from above is set to:

.. math:: \overline{\frac{\partial q_p}{\partial t}} = \frac{1}{\rho \Delta z} P

(where :math:`P` is the precipitation fall-flux from above), and the
area-fraction in-which this source term applies is set to:

.. math:: C_{proc} = {C_R}_{fall}

Precipitation fraction created by “emergency melting”
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

|  
| Again this follows what is done under i_update_precfrac = 1, (section
  `5.4.3.3 <#sec:precfrac:emerg>`__) but using eq
  (`[eq:cr_np1] <#eq:cr_np1>`__) to compute the combined fraction of the
  existing rain / graupel and the melted snow-flux.

And the final check to reset :math:`C_R` to zero if rain / graupel mass
has fallen to zero is retained the same under i_update_precfrac = 2.

Parametrized Microphysical Process Terms
========================================

.. _`sec:trans_intro`:

Introduction
------------

The Parametrization of each transfer processes will be discussed below.
Each one also has an associated latent heat transfer involved, which
will modify the temperature of the gridbox. This won’t be explicitly
stated below, but can be assumed. We also include, for completeness, a
summary of the cloud fraction changes as a result of each process,
(which can be passed to PC2), although these do change from model
version to model version.

The equations governing the transfer of moisture from one category to
another can be written in qualitative form, in a similar way to
:raw-latex:`\cite{Rutledge:Hobbs:1983}`, as:

- :math:`\frac{Dq}{Dt}` = (Sublimation of Crystals and Aggregates
  :math:`+` Evaporation) :math:`-` (Deposition of Crystals and
  Aggregates :math:`+` Heterogeneous Nucleation)

- :math:`\frac{Dq_{cl}}{Dt}` = :math:`-`\ (Droplet settling + Rain
  Autoconversion :math:`+` Riming :math:`+` Rain Accretion :math:`+`
  Deposition :math:`+` Heterogeneous Nucleation :math:`+` Homogeneous
  Nucleation)

- :math:`\frac{Dq_R}{Dt}` = (Fall into layer :math:`-` Fall out of
  layer) :math:`+` (Rain Autoconversion :math:`+` Rain Accretion
  :math:`+` Melting) :math:`-`\ (Evaporation :math:`+` Capture :math:`+`
  Homogeneous Nucleation)

- :math:`\frac{Dq_{cfa}}{Dt}` = (Fall into layer :math:`-` Fall out of
  layer) :math:`+` (Deposition :math:`+` Capture :math:`+` Riming
  :math:`+` Aggregation) :math:`-` (Graupel autoconversion :math:`+`
  Graupel Capture :math:`+` Sublimation :math:`+` Melting of aggregates)

- :math:`\frac{Dq_{cfc}}{Dt}` = (Fall into layer :math:`-` Fall out of
  layer) :math:`+` (Deposition :math:`+` Capture :math:`+` Riming
  :math:`+` Heterogeneous Nucleation :math:`+` Homogeneous Nucleation)
  :math:`-` (Aggregation of crystals :math:`+` Sublimation :math:`+`
  Melting :math:`+` Capture by aggregates)

- :math:`\frac{Dq_{graup}}{Dt}` = (Fall into layer :math:`-` Fall out of
  layer) :math:`+` (Graupel Autoconversion :math:`+` Riming :math:`+`
  Capture) :math:`-` Melting

It should be noted that the heterogeneous nucleation and the deposition
terms can convert both liquid and vapour to the ice categories, both of
which can receive ice mass. Some other variables have inputs from a
number of sources. For example, rain (:math:`q_R`) increases by the
melting of crystals, aggregates and graupel. Similarly, :math:`q_R` can
be decreased by capture by crystals, aggregates or graupel. Evaporation
can be of various quantities (including settling cloud droplets, rain,
melting ice or snow). Melting and capture can again be in various
microphysical categories.

Quantitatively, the transfers of moisture from one category to another
can be written as follows:

.. math::

   \begin{aligned}
   \frac{D q}{Dt}&=&P_{SSUB}+P_{REVP}+P_{ISUB}
         +P_{SMLTEV}+P_{IMLTEV}     \nonumber \\
         & & +P_{LSET2} -(P_{SDEP2}+P_{IDEP2}+P_{IPRM2} )
                                                              \\[0.6cm]
   \frac{D q_{cl}}{Dt}&=&\frac{1}{\rho}\frac{\partial}{\partial z}
          (\rho q_{cl} [V]_{q_{cl}}) \nonumber \\
   && -(P_{LSET2} + P_{RAUT}+P_{SACW}+P_{RACW}+P_{GACW}\nonumber\\
         & & + P_{SDEP1}+ P_{IDEP1} + P_{IACW} + P_{IPRM1}+P_{IFRW} )
                                                              \\[0.6cm]
   \frac{D q_R}{Dt}&=&\frac{1}{\rho}\frac{\partial}{\partial z}
          (\rho q_R [V]_{q_R})                              \nonumber\\
          &&+P_{RAUT}+P_{RACW}+P_{SMLT}+P_{IMLT}+P_{GMLT} \nonumber \\
         & &     -(P_{REVP}+P_{SACR-A}+P_{SACR-G}+P_{IACR-C} \nonumber \\
         & &     + P_{IACR-G}+P_{IFRR})
                                                              \\[0.6cm]
   \frac{D q_{cfa}}{Dt}&=&\frac{1}{\rho}\frac{\partial}{\partial z}
          (\rho q_{cfa} [V]_{q_{cfa}})  \nonumber    \\
         & &+P_{SAUT}+ P_{SDEP}+P_{SACI}+P_{SACR-A}+P_{SACW} \nonumber   \\
         & &      -(P_{GAUT}+P_{GACS}+P_{SSUB}+P_{SMLT}+P_{SMLTEV})
                                                              \\[0.6cm]
   \frac{D q_{cfc}}{Dt}&=&\frac{1}{\rho}\frac{\partial}{\partial z}
          (\rho q_{cfc} [V]_{q_{cfc}})     \nonumber    \\
        & &+P_{IDEP}+P_{IACR-C}+P_{IPRM}+P_{IACW} + P_{IFRW} +P_{IFRR} \nonumber    \\
       & & -(P_{ISUB} +  P_{IMLT} + P_{IMLTEV} + P_{SAUT} + P_{SACI})
                                                              \\[0.6cm]
   \frac{D q_{graup}}{Dt} &=& \frac{1}{\rho}\frac{\partial}{\partial z}
          (\rho q_{graup} [V]_{q_{graup}} ) \nonumber \\
       & &+P_{GAUT}+P_{GACW}+P_{GACS}+P_{SACR-G}+P_{IACR-G} \nonumber \\
       & &- P_{GMLT}
   \end{aligned}

where each of the transfer terms above are defined in table
`13 <#tab:rates>`__. The subscript numbers 1 and 2 indicates first and
second transfers, where transfer to more than one category is possible.
Note also that the flux terms in all categories except :math:`q` are
represented in section `6.3 <#sec:trans_eqs>`__ by PRFALL, PIFALL,
PSFALL and PGFALL for rain, ice, snow and graupel respectively and cloud
droplet fall is represented as PLSET1 (sedimentation where no
evaporation takes place). :math:`[V]` is a bulk fall velocity of the
appropriate category of rain, graupel, ice aggregates or ice crystals,
as ilustrated by the subscript.

.. container:: center

   .. container::
      :name: tab:rates

      .. table:: Details of the process conversion terms that are
      modelled in the UM microphysics parametrizations. :math:`q` is
      vapour mixing ratio, :math:`q_{cl}` liquid water mixing ratio,
      :math:`q_{cfa}` ice aggregate mixing ratio, :math:`q_R` rain
      mixing ratio, :math:`q_{cfc}` ice crystal mixing ratio and
      :math:`q_{graup}` is graupel mixing ratio. Sedimentation processes
      are ignored as they do not change the microphysical category.

         +--------+------------------+------------------+------------------+
         | Code   | Sink             | Source           | Description      |
         +========+==================+==================+==================+
         | RACW   | :math:`q_{cl}`   | :math:`q_R`      | Collection of    |
         |        |                  |                  | liquid cloud by  |
         |        |                  |                  | rain             |
         +--------+------------------+------------------+------------------+
         | RAUT   | :math:`q_{cl}`   | :math:`q_R`      | Autoconversion   |
         |        |                  |                  | from liquid      |
         |        |                  |                  | cloud to rain    |
         |        |                  |                  | due to liquid    |
         +--------+------------------+------------------+------------------+
         |        |                  |                  | cloud droplet    |
         |        |                  |                  | aggregation      |
         +--------+------------------+------------------+------------------+
         | REVP   | :math:`q_R`      | :math:`q`        | Evaporation of   |
         |        |                  |                  | rain             |
         +--------+------------------+------------------+------------------+
         | LSET   | :math:`q_{cl}`   | :math:`q_{cl}`   | Droplet settling |
         |        |                  | or :math:`q`     |                  |
         +--------+------------------+------------------+------------------+
         | IACW   | :math:`q_{cl}`   | :math:`q_{cfc}`  | Collection of    |
         |        |                  |                  | liquid cloud by  |
         |        |                  |                  | cloud ice        |
         |        |                  |                  | (Riming)         |
         +--------+------------------+------------------+------------------+
         | IDEP   | :math:`q_{cl}`   | :math:`q_{cfc}`  | Deposition of    |
         |        | or :math:`q`     |                  | vapour on to     |
         |        |                  |                  | cloud ice        |
         +--------+------------------+------------------+------------------+
         | IPRM   | :math:`q_{cl}`   | :math:`q_{cfc}`  | Primary          |
         |        | or :math:`q`     |                  | nucleation of    |
         |        |                  |                  | ice crystals by  |
         |        |                  |                  | heterogeneous    |
         |        |                  |                  | ice nuclei       |
         +--------+------------------+------------------+------------------+
         | IFRW   | :math:`q_{cl}`   | :math:`q_{cfc}`  | Nucleation of    |
         |        |                  |                  | ice crystals by  |
         |        |                  |                  | homogeneous      |
         |        |                  |                  | freezing of      |
         +--------+------------------+------------------+------------------+
         |        |                  |                  | liquid cloud     |
         |        |                  |                  | drops            |
         +--------+------------------+------------------+------------------+
         | IMLT   | :math:`q_{cfc}`  | :math:`q_R`      | Cloud ice        |
         |        |                  |                  | melting to form  |
         |        |                  |                  | rain             |
         +--------+------------------+------------------+------------------+
         | ISUB   | :math:`q_{cfc}`  | :math:`q`        | Sublimation of   |
         |        |                  |                  | cloud ice        |
         +--------+------------------+------------------+------------------+
         | IMLTEV | :math:`q_{cfc}`  | :math:`q`        | Evaporation of   |
         |        |                  |                  | melting ice      |
         +--------+------------------+------------------+------------------+
         | IACR-C | :math:`q_R`      | :math:`q_{cfc}`  | Collection of    |
         |        |                  |                  | rain by ice      |
         |        |                  |                  | crystals to form |
         |        |                  |                  | ice crystals.    |
         +--------+------------------+------------------+------------------+
         | IACR-G | :math:`q_R`      | :math:`q_{g}`    | Collection of    |
         |        |                  |                  | rain by ice      |
         |        |                  |                  | crystals to form |
         |        |                  |                  | graupel.         |
         +--------+------------------+------------------+------------------+
         | SACW   | :math:`q_{cl}`   | :math:`q_{cfa}`  | Collection of    |
         |        |                  |                  | liquid cloud by  |
         |        |                  |                  | snow (Riming)    |
         +--------+------------------+------------------+------------------+
         | SDEP   | :math:`q_{cl}`   | :math:`q_{cfa}`  | Deposition of    |
         |        | or :math:`q`     |                  | vapour on to     |
         |        |                  |                  | snow             |
         +--------+------------------+------------------+------------------+
         | SMLT   | :math:`q_{cfa}`  | :math:`q_R`      | Melting of snow  |
         |        |                  |                  | to form rain     |
         +--------+------------------+------------------+------------------+
         | SSUB   | :math:`q_{cfa}`  | :math:`q`        | Sublimation of   |
         |        |                  |                  | snow             |
         +--------+------------------+------------------+------------------+
         | SMLTEV | :math:`q_{cfa}`  | :math:`q`        | Evaporation of   |
         |        |                  |                  | melting snow     |
         +--------+------------------+------------------+------------------+
         | SACR-A | :math:`q_R`      | :math:`q_{cfa}`  | Collection of    |
         |        |                  |                  | rain by snow to  |
         |        |                  |                  | form snow        |
         +--------+------------------+------------------+------------------+
         | SACR-G | :math:`q_R`      | :math:`q_{g}`    | Collection of    |
         |        |                  |                  | rain by snow to  |
         |        |                  |                  | form graupel     |
         +--------+------------------+------------------+------------------+
         | SAUT   | :math:`q_{cfc}`  | :math:`q_{cfa}`  | Aggregation of   |
         |        |                  |                  | crystals to form |
         |        |                  |                  | snow             |
         +--------+------------------+------------------+------------------+
         | SACI   | :math:`q_{cfc}`  | :math:`q_{cfa}`  | Collection of    |
         |        |                  |                  | ice crystals by  |
         |        |                  |                  | snow aggregates  |
         +--------+------------------+------------------+------------------+
         | GAUT   | :math:`q_{cfa}`  | :                | Autoconversion   |
         |        |                  | math:`q_{graup}` | of snow          |
         |        |                  |                  | aggregates to    |
         |        |                  |                  | graupel          |
         +--------+------------------+------------------+------------------+
         | GACW   | :math:`q_{cl}`   | :                | Collection of    |
         |        |                  | math:`q_{graup}` | liquid cloud by  |
         |        |                  |                  | graupel (Riming) |
         +--------+------------------+------------------+------------------+
         | GACS   | :math:`q_{cfa}`  | :                | Collection of    |
         |        |                  | math:`q_{graup}` | snow aggregates  |
         |        |                  |                  | by graupel       |
         +--------+------------------+------------------+------------------+
         | GMLT   | :                | :math:`q_{R}`    | Melting of       |
         |        | math:`q_{graup}` |                  | graupel to form  |
         |        |                  |                  | rain             |
         +--------+------------------+------------------+------------------+

.. _`sec:gr_tr`:

A note on graupel transfers not included
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

At this stage, the following transfer terms have not been represented as
they are small in comparison with the terms in table
`13 <#tab:rates>`__:

- Deposition and sublimation of graupel

- The wet mode of graupel growth.

- Collection of ice crystals (only collection of aggregates is assumed)

- Freezing of rain (from vn11.2 there is an option to include this
  process)

.. _`sec:cloud_drop_calc`:

Calculation of cloud drop number
--------------------------------

Calculation of cloud droplet number (:math:`n_d`) is important for the
autoconversion and droplet settling transfer processes. Cloud drop
number is the concentration of activated cloud nuclei. :math:`n_d` can
be specified as a simple constant, depending only upon whether the grid
point is a land or sea point, or it can be dependent on model aerosol.
Sections `6.2.1 <#sec:landsea>`__ to `6.2.5 <#sec:easy_cdnc>`__ outline
some of the possible options.

.. _`sec:landsea`:

Using a simple land-sea mask
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The simplest option available is to choose one value for the drop
concentration over land and another over sea. This is intended to
represent the fact that maritime air is less polluted than continental
air. Some sample values are shown in table `14 <#tab:drop_num>`__,
although many other varieties of this land-sea split do exist in the
literature.

.. container:: center

   .. container::
      :name: tab:drop_num

      .. table:: Land-sea droplet number concentrations

         +----------------------+----------------------+----------------------+
         |                      | :math:`n_d(land)`    | :math:`n_d(sea)`     |
         +======================+======================+======================+
         | UM Default           | :math:`3.0           | :math:`1.0           |
         |                      |  \times 10^8~m^{-3}` |  \times 10^8~m^{-3}` |
         +----------------------+----------------------+----------------------+
         | :                    | :math:`6.0           | :math:`1.5           |
         | raw-latex:`\cite{Bow |  \times 10^8~m^{-3}` |  \times 10^8~m^{-3}` |
         | er:Choularton:1992}` |                      |                      |
         +----------------------+----------------------+----------------------+

The disadvantage of this method is that in stratocumulus drizzling
clouds, the model often has a distinct split in drizzle fields, which
looks rather unrealistic. To get around this issue, we can use aerosol
amounts, as detailed in the next section.

.. _`sec:CLASSIC`:

Using the CLASSIC aerosol species
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is a common option in the climate model simulations, but rarely
used for NWP. The droplet number is related to the total aerosol
*number* concentration, :math:`n_{aer}`. This is derived from the
CLASSIC aerosol species :raw-latex:`\citep{Bellouin:etal:2007}` and the
result converted to :math:`n_{d}`, using the
:raw-latex:`\cite{Jones:etal:1994}` relationship:

.. math::

   \label{eq:Jones_Nature}
   n_{d} = 3.75 \times 10^8 \left[ 1 - \exp 
   \left( -2.5 \times 10^{-9} n_{aer} \right) \right].

The droplet number derived by this method is limited to minimum values
of :math:`35 
\times 10^6` m\ :math:`^{-3}` over land and
:math:`5 \times 10^6` m\ :math:`^{-3}` over the sea, sea-ice and
ice-sheets.

The input of CLASSIC aerosols can either be a prognostic variable or a
fixed climatology. Prognostic variables are common in climate
simulations, but are generally too expensive to use in NWP models. So,
in NWP models, the use of climatological aerosols provides a useful
alternative to the land-sea mask discussed in section
`6.2.1 <#sec:landsea>`__. The droplet number derived from the
climatological aerosols can be scaled in order to account for any
discrepencies between the prognostic and climatological aerosol inputs.

.. _`sec:UKCA_cdnc`:

Using the UKCA-derived cloud drop number concentration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The UKCA model (see :umdp:‘084‘) is capable of producing a cloud drop
number concentration derived from aerosol. This can be passed into the
UM microphysics and used in the process rates. In this case, the
microphysics scheme does not modify the UKCA-derived cloud drop number
concentration.

.. _`sec:murk2nd`:

Using MURK aerosol
~~~~~~~~~~~~~~~~~~

Total (or ‘MURK’) aerosol is a prognostic mass-mixing ratio of a single
aerosol species that is designed to broadly represent the behaviour of
the whole aerosol spectrum, in a simplistic way. In order to diagnose a
cloud drop number concentration, the aerosol mass must first be
converted into an aerosol number (:math:`n_{aer}`). Then, a portion of
the aerosol number concentration can be activated to produce a value of
cloud drop number, which is used in the microphysical calculations.

This scheme uses the parametrization of either
:raw-latex:`\cite{Clark:etal:2008}` or
:raw-latex:`\cite{Haywood:etal:2008}` using flight data around the UK.
Both relations share the same equation

.. math::

   \label{eq:new_murk}
   n_{aer}= n_{0_{murk}} \left( \frac{A_{mass}}
   {S_{\rm murk} \, m_{0_{murk}} } \right)^{\frac{1}{2}},

where :math:`A_{mass}` is the prognostic mass mixing ratio of the
aerosol and :math:`S_{\rm murk}` is a tuning parameter that allows the
relationship between murk and cloud drop number to be adjusted
independently from the visibiltiy. The values of the other parameters
are given in table `15 <#tab:haycla>`__

.. container:: center

   .. container::
      :name: tab:haycla

      .. table:: MURK aerosol parameters used in equation
      `[eq:new_murk] <#eq:new_murk>`__

         +----------------------+----------------------+----------------------+
         |                      | :math:`n_{0_{murk}}` | :math:`m_{0_{murk}}` |
         +======================+======================+======================+
         | :raw-latex:`\ci      | :ma                  | :math:`1.            |
         | te{Clark:etal:2008}` | th:`5.0 \times 10^8` | 4584 \times 10^{-8}` |
         +----------------------+----------------------+----------------------+
         | :raw-latex:`\cite    | :ma                  | :math:`1.            |
         | {Haywood:etal:2008}` | th:`2.0 \times 10^9` | 8956 \times 10^{-8}` |
         +----------------------+----------------------+----------------------+

:raw-latex:`\cite{Wilkinson:etal:2010:ams}` showed that generating the
cloud droplet number using the :raw-latex:`\cite{Jones:etal:1994}`
relationship (equation `[eq:Jones_Nature] <#eq:Jones_Nature>`__)
constrained the cloud droplet numbers into a sensible range of values.
However :raw-latex:`\cite{Abel:2012}` used aircraft data to suggest that
the :raw-latex:`\cite{Haywood:etal:2008}` parametrization overestimated
the cloud drop number concentration and that the
:raw-latex:`\cite{Clark:etal:2008}` gave a better representation of the
droplet spectrum when coupled to the :raw-latex:`\cite{Jones:etal:1994}`
relation.

.. _`sec:easy_cdnc`:

Using EasyAerosol
~~~~~~~~~~~~~~~~~

The EasyAerosol prescription of cloud droplet number concentration can
be used to provide cloud droplet number directly. The corresponding
model switch, l_easyaerosol_autoconv, triggers the input of a
four-dimensional (latitude, longitude, model level, time) distribution
of cloud droplet number concentration (in m\ :math:`^{-3}`) stored in
the netCDF file specified in the easy_aerosol namelist. Consult the
aerosol modelling group for advice on creating the input file. Note that
the same distribution can also be used in the calculation of cloud
albedo, see UMDP23 section 3.3.

.. _`sec:drop_taper`:

Drop tapering
~~~~~~~~~~~~~

:raw-latex:`\cite{Price:2011}` showed that drop concentrations were much
lower in fog than in stratocumulus cloud, with concentrations varying
between 20 per cm\ :math:`^3` and 100 per cm\ :math:`^3`.
:raw-latex:`\cite{Wilkinson:etal:2012}` derived a parametrization to
taper (or reduce) the drop number concentration in the boundary layer,
with lower values closer to the surface. This can be used in conjunction
with the MURK and CLASSIC aerosols as described in sections
`6.2.2 <#sec:CLASSIC>`__ and `6.2.4 <#sec:murk2nd>`__. The surface drop
concentration can either be fixed or can vary with aerosol mass mixing
ratio.

For a fixed taper, the droplet number at a given height is defined as

.. math::

   \label{eq:taper}
   n_d = n_{ds} + \sigma \ln \left( \frac{\eta}{\eta_{s}} \right)

where :math:`\eta = z / z_{toa}`, :math:`z` is the altitude of the model
level and :math:`z_{toa}` is the altitude at the top of the model.
:math:`n_{ds}` is the minimum droplet at a specified :math:`\eta_{s}`;
the height of this ’surface’ value is specified via a namelist parameter
:math:`z_s`, and a constant value of :math:`n_d=n_{ds}` is used below
this. :math:`\sigma` is defined as

.. math::

   \label{eq:sigma}
   \sigma = \frac{n_{dth} - n_{ds}}{\ln \left( \frac{\eta_{th}}{\eta_{s}} \right) }

and the taper height :math:`z_{th}` is defined as the product of
:math:`\eta_{th}` and :math:`z_{toa}`.

Hence, above the taper height, the aerosol is unaffected by tapering.
The taper height used operationally is typically around 150 m, with a
surface drop number of 75 per cm\ :math:`^3` (7.5 :math:`\times 10^7`
m\ :math:`^{-3}`).

If a variable taper is used, the value of :math:`n_{ds}` is calculated
based on the aerosol amount in the lowest model level
(:math:`n_{aer_{s}}`) as a modified version of equation
`[eq:Jones_Nature] <#eq:Jones_Nature>`__:

.. math::

   \label{eq:tapvar}
   n_{ds} = n_{ds_{max}} \left[1.0 - \exp \left( - 1.5 \times 10^{-9}  n_{aer_{s}} \right) \right].

and a typical value of :math:`n_{ds_{max}}` is 100 per cm\ :math:`^3`
(1.0 :math:`\times 10^8` m\ :math:`^{-3}`).

Finally, if drop taper is selected but neither MURK nor classic aerosol
are selected, the land-sea mask is ignored and a simple assumed profile
of cloud droplet number applies. This uses the taper height and surface
droplet concentration set by the user. However, at the taper height, the
cloud drop concentration is assumed to be 375 per cm\ :math:`^3`, which
is relaxed smoothly to 100 per cm\ :math:`^3` at 2 km altitude. Above 2
km altitude, the drop number remains constant at 100 per cm\ :math:`^3`.

.. _`sec:trans_eqs`:

Transfer equations
------------------

We next look at these terms from section `6.1 <#sec:trans_intro>`__ in
detail. The order of terms approximately follows the order that they
appear in the microphysics scheme.

.. _`sec:PLSET`:

PLSET: Droplet Settling
~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cl}`, :math:`q_{cl}` to :math:`q`** This
term is intended to update the cloud prognostics as a results of
allowing cloud droplets to fall out by gravity using a modified Stokes’
law. The terminal velocity of a cloud droplet is given as follows (after
:raw-latex:`\citealp{Lamb:1994, Rogers:Yau:1989}`)

.. math::

   \label{eq:ds_lamb}
   V_{cd} = \frac{2}{9} \frac{\rho_w g}{\mu} \left(\frac{D}{2}\right)^2 
          = \mathcal{K}_1 \left(\frac{D}{2}\right)^2

where :math:`\mathcal{K}_1 = 1.27 \times 10^8` m\ :math:`^{-1}`
s\ :math:`^{-1} /F_{K_{a}}` (and :math:`F_{K_{a}}`\ is defined in
equation `[eq:mic_conductivity] <#eq:mic_conductivity>`__). Equation
`[eq:ds_lamb] <#eq:ds_lamb>`__ is accurate for droplet radii of up to 30
microns. Damian Wilson has integrated over the cloud droplet spectrum,
assuming a :raw-latex:`\cite{Khrgian:Mazin:1952}` gamma distribution,
which gives the bulk settling velocity as

.. math::

   \label{eq:ds_spec}
   \overline{V_{cd}} = \frac{1.339 \times 10^6 
   \left(\frac{q_{cl} \rho}{n_{d}}\right)^{\frac{2}{3}}}{F_{K_a}},

where :math:`n_d` is the cloud droplet number concentration, determined
in section `6.2 <#sec:cloud_drop_calc>`__.

With the bulk velocity for cloud droplets known, the flux of cloud
droplets out of the layer can be calculated as

.. math::

   \label{eq:ds_flux}
   P_{LSET} = \rho q_{cl}\overline{V_{cd}},

with the restriction that the droplets are not allowed to settle more
than one vertical grid box per timestep. Given the settling velocity of
the droplets is of the order of cm s\ :math:`^{-1}`, this should be
physically realistic.

When droplets are passed from one grid box to the one below, no
assumption is currently made of cloud fraction in the first box; it is
simply assumed that there is a uniform distribution of droplets settling
into the grid box below. However, the liquid cloud fraction of the lower
grid box into which the droplets are settling is used. The distribution
that falls into the cloudy part of the grid box will be converted into
:math:`q_{cl}`, and results in a transfer of cloud liquid content
downwards. That which falls into the clear part of the grid box will be
converted into :math:`q` and increase the humidity in the grid box.

PIFALL/PSFALL: Sedimentation (fall) of ice (aggregates and crystals)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This term is scientifically just the flux divergence of the ice across
the layer in each model column. Its numerical solution is not
straightforward because of the long timestep and the way in which it is
solved is discussed in the numerical methods section. The solution to
the mass mean fall-speed condensate-content relationship is:

.. math::

   \overline{v_x} = {\left( \frac{\rho_0}{\rho} \right)}^{\mathcal{G}_x} c_x
   \frac{ \Gamma \left( d_x + b_x + 1 + \alpha_x \right) }{ \Gamma \left( b_x + 1 
   + \alpha_x \right) }
   { \left( \frac{ \rho q_{x} }{n_{ax} a_x \Gamma \left( b_x + 1 + 
   \alpha_x \right) } \right)}
   ^{\frac{d_x}{b_x + 1 + \alpha_x - n_{bx} }}
   \label{eq:icefall}

where :math:`q_x` is the mixing ratio variable for the condensate
quantity (:math:`q_{cfa}`, :math:`q_{cfc}`, :math:`q_{graup}` or
:math:`q_R`). The parameters have already been defined in section
`4 <#sec:param_par_char>`__. See tables `2 <#tab:mic_consts_psd>`__,
`5 <#tab:mic_consts_fallspeed>`__ and `9 <#tab:mic_consts_density>`__
for the default values used in the UM.

**With the generic ice particle size distribution** When the generic ice
particle option is switched on, equation `[eq:icefall] <#eq:icefall>`__
is modified as follows (now using the ’\ :math:`a`\ ’ subscript as this
is valid for ice aggregates only):

.. math::

   \overline{v_a} = {\left( \frac{\rho_0}{\rho} \right)}^{\mathcal{G}_a} c_a a_a 
   \left(\frac{\mathcal{M}_{b_a+d_a}}{\rho q_{cfa}}\right) 
   \label{eq:icefallpsd}

where :math:`\mathcal{M}_{b_a+d_a}` is the result of inputting the
expression :math:`b_a + d_a` into the generic ice particle size
distribution calculation (equation `[eq:field1] <#eq:field1>`__,
described in section `4.3 <#sec:field_psd>`__).

**Cloud fraction changes** We assume that :math:`C_i` is not reduced if
ice falls out of a layer (since slower falling ice particles will be
left behind), but it is increased if ice falls in from above. The amount
of :math:`C_i` falling in from above is determined by the overlap of
:math:`C_i` above with the :math:`C_i` in the current layer. This has
been parametrized assuming that there is a generally maximum overlap
between the layers, but a significant amount of non-maximum overlap as
well. This is to represent the effect of wind-shear, although the code
does not currently explicitly use the wind-shear but represents the
effect with a single parameter.

.. math::

   \frac{\partial{C_i}}{\partial t} = \mbox{\footnotesize \sf MAX} \left[ 
   \frac{\partial{C_i}}{\partial z}~,~0\right]   v_i + ws

where :math:`v_i` is the mass-weighted mean fall speed of the aggregates
and crystals and :math:`ws` is currently set to a constant,
:math:`ws=1 \times 10^{-4} s^{-1}`, which is a typical baseline value
for the wind-shear parameter.

.. _`sec:PRFALL`:

PRFALL: Sedimentation (fall) of rain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Prognostic rain.** For the mixing ratio (prognostic rain) version of
the scheme this term takes the same form as for the fall of ice;
equation `[eq:icefall] <#eq:icefall>`__ is used, although the quantities
with the :math:`x` subscript become those for rain listed in tables
`2 <#tab:mic_consts_psd>`__ and `5 <#tab:mic_consts_fallspeed>`__.

**Diagnostic rain** In the flux (diagnostic rain) version of the scheme
the rain variable is assumed to fall entirely out of the model column
within the timestep. In each grid box in the vertical, the magnitude of
the flux of rain can be altered by other transfer processes. However,
after precipitation is initiated, the fall speed of the diagnostic rain
flux remains unaltered by changes to the drop size distribution and fall
speed parameters in tables `2 <#tab:mic_consts_psd>`__ and
`5 <#tab:mic_consts_fallspeed>`__. However, all transfer processes are
still applied and increase or decrease the magnitude of the rain rate.

PGFALL: Sedimentation (fall) of graupel
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All graupel is assumed to be prognostic; there is no diagnostic graupel
available. The fall term takes the same form as for the fall of ice;
equation `[eq:icefall] <#eq:icefall>`__ is used, although the quantities
with the :math:`x` subscript become those for graupel listed in tables
`2 <#tab:mic_consts_psd>`__ and `5 <#tab:mic_consts_fallspeed>`__.

PIPRM: Heterogeneous nucleation (Deposition on to natural ice nuclei)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cfc}`, :math:`q` to :math:`q_{cfc}`.**
This term provides a small ‘seed’ ice content for ice free clouds in
order that the other microphysical terms can grow it. The term acts if
all the following criteria are satisfied:

.. math::

   \begin{aligned}
   T_c   <& -10 \deg C    &   \nonumber\\
   RH  >& RH_{inuc}   & RH_{inuc}=\mbox{\footnotesize \sf MIN} \left[~0.01(188.92+2.81 T_c +0.013336~{T_c}^2), 1.0~\right]   
   - 0.1 \nonumber \\
   q_i <& q_{inuc}    & q_{inuc} = \frac{m_0}{\rho} ~\mbox{\footnotesize \sf MIN} \left[~0.01~\exp (-0.6~T_c), 1
   \times 10^5~\right]  
   \label{eq:mic_um_hetnuc}
   \end{aligned}

where :math:`m_0=1 \times 10^{-12}` represents the mass of a single,
newly nucleated ice particle, :math:`RH=(q+q_{cl})/q_{sat~water}` and
:math:`T_c` is the temperature in degrees Celsius. :math:`q_{inuc}` is
the combined mass of the number of active nuclei produced per timestep
following the temperature dependent function suggested by
:raw-latex:`\cite{Fletcher:1962}`. The other criteria restrict the
nucleation term to low temperatures and regions of high vapour content
:raw-latex:`\citep{Heymsfield:Milo:1995}`. This nucleated ice content is
first removed from the available liquid water, and then from available
vapour (hence :math:`P_{IPRM1}` and :math:`P_{IPRM2}` terms). It is
added to the :math:`q_{cfc}` (rather than :math:`q_{cfa}`). The amount
of ice nucleated is not critical to the evolution of the model, the
deposition terms will fairly rapidly grow the nucleated ice and other
model balances will dominate the model. If a prognostic number
concentration was used, as in some CRMs, then the nucleation term
becomes more important.

The scheme additionally restricts nucleation to regions where liquid
water is present (the :math:`RH_{inuc}` term still restricts the amount
of ice that can be nucleated) and assumes that nucleation occurs in all
locations within the liquid cloud volume, so :math:`C_i` is set equal to
:math:`C` if there is a nucleation increment.

.. _`sec:tnuc_dust`:

Prognostic dust approach
~~~~~~~~~~~~~~~~~~~~~~~~

This approach is intended to mimic the role of ice nucleation particles
(INPs) in the atmosphere which are not incorporated within the UM
single-moment microphysics scheme. Currently the heterogeneous
nucleation is controlled by the temperature dependent function suggested
by :raw-latex:`\cite{Fletcher:1962}`. By activating the prognostic dust
approach,the heterogeneous nucleation temperature can be defined to vary
three dimensionally globally as an arc-tangent function of the mineral
dust distribution in the model. This will delay the heterogeneous
nucleation in regions with lower dust number density (cleaner
environments like the Southern Ocean where INPs are relatively scarce)
by lowering cloud freezing temperatures relative to other regions. E.g:

.. math::

   \label{eqn:progtnuc}
       tnuc_n = t_{homo} + \left(tnuc-t_{homo}\right) \times \left( \frac{ \arctan \left({5 \times \log_{10}} \left(\frac{dust}{refdust}\right ) \right)}{\pi}+0.5 \right)

where :math:`tnuc_n` (:math:`^{\circ}`\ C) = the new heterogeneous
nucleation temperature as function of dust, :math:`t_{homo}` =
:math:`-40^{\circ}`\ C (the homogeneous nucleation temperature),
:math:`tnuc` = :math:`-10^{\circ}`\ C (the default heterogeneous
nucleation temperature), :math:`dust` (number of dust particles per
:math:`m^3`) = total dust number density (sum of all 6 (or 2) dust bins
depending on 6-bin or 2-bin schemes; also available with dust
climatology), :raw-latex:`\cite{Woodward:2001}`) and :math:`refdust` =
an arbitrary reference total dust number density value. In the event
that no dust is present, the heterogeneous freezing temperature relaxes
to the homogeneous nucleation temperature, :math:`t_{homo}`.

.. container:: float
   :name: fig:tnucnew

   .. container:: centering

      |image1|

In order to implement this approach, the logical switch l which appears
under Mixed phase processes in Section 04 in rose GUI needs to be set to
true. Additionally, by activating this approach, the default detrainment
temperature thresholds would also be replaced in the convection scheme.
For further details, please refer to :umdp:‘030‘.

PIFRW: Homogeneous nucleation of liquid water
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cfc}`.** All liquid water at temperatures
less than :math:`-40^{\circ}`\ C is instantaneously frozen to form ice
particles (:math:`q_{cfc}`), according to
:raw-latex:`\cite{Rogers:Yau:1989}`. In the scheme :math:`C_i` is set
equal to :math:`C` and :math:`C_l` set to zero.

.. _pifrw-homogeneous-nucleation-of-liquid-water-1:

PIFRW: Homogeneous nucleation of liquid water
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cfc}`.** All liquid water at temperatures
less than :math:`-40^{\circ}`\ C is instantaneously frozen to form ice
particles (:math:`q_{cfc}`), according to
:raw-latex:`\cite{Rogers:Yau:1989}`. In the scheme :math:`C_i` is set
equal to :math:`C` and :math:`C_l` set to zero.

PIFRR: Homogeneous nucleation of rain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{R}` to :math:`q_{cfc}`.** As PIFRW, but for rain rather than
liquid water.

PIPRR: Heterogeneous freezing of rain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{R}` to :math:`q_{graup}`.** From vn11.2 there is an option
to include heterogeneous freezing of rain. Following
:raw-latex:`\citealp{Bigg:1953}`, the heterogeneous freezing of rain is
given by

.. math::

   P_{PIPRR}=20\pi\ B^\prime n_{0R}\left(\frac{\rho_w}{\rho}\right)\ 
                \left\{\exp{\left[A^\prime\left(T_0-T\right)\right]}-1\right\}\lambda_R^{-7}
   \label{eq:mic_rainfreeze}

where :math:`A^\prime` and :math:`B^\prime` are parameters determined by
laboratory experiments and defined as :math:`0.66` C\ :math:`^{-1}` and
100 :math:`m^{-3}~ s^{-1}` respectively, and :math:`T_0-T` is the
difference between :math:`0` C and the temperature.

The heterogeneous freezing rain term is only active if the temperature
is :math:`< -4` C and the rain water mixing ratio exceeds a small
threshold of :math:`1\times10^{-8}~kg~ kg^{-1}`.

If graupel is being used :math:`P_{PIPRR}` is a source term for graupel,
otherwise it is a source term for ice aggregates.

**Cloud fraction changes** There is no change to the rain fraction from
this term, except if all of the rain freezes :math:`C_R` is set to
:math:`0`. If using the prognostic precipitation fraction, the change of
rain fraction is calculated differently; see section
`5.4.3.1 <#sec:precip_frac_update>`__. If this term acts as a source of
ice aggregates, the ice cloud fraction after this process is taken to be
the :math:`\mbox{\footnotesize \sf MAX} \left[C_R,C_i\right]`, which
assumes that nucleation occurs throughout the rain volume.

.. _`sec:psdep_pssub`:

PSDEP/PSSUB: Deposition/Sublimation of vapour on to aggregates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cfa}`, :math:`q` to :math:`q_{cfa}`.** The
deposition/sublimation equation is (following
:raw-latex:`\citealp{Rogers:Yau:1989}` or
:raw-latex:`\citealp{Rutledge:Hobbs:1983}`):

.. math::

   \frac {dM_{x}}{dt}=\frac{ \left(\frac{q}{q_{isat}}-1\right)}
                              {\mbox{AB}} C F'.
   \label{eq:mic_dmevap}

where :math:`dM_x/dt` represents the rate of change of mass due to the
phase change, :math:`\mbox{AB}` is a function of temperature and is
different for ice or liquid particles, :math:`C` is the shape parameter,
for spherical particles :math:`C=2 \pi D`, and :math:`F'` is the
ventilation coefficient. The scheme uses the ventilation factor of
:raw-latex:`\cite{Thorpe:Mason:1966}`, which is applicable for hexagonal
plates:

.. math:: F'=0.65+0.44S_c^{\frac{1}{3}} R_e^\frac{1}{2}

where :math:`R_e` is the Reynolds number given by

.. math:: R_e = \frac{V_x(D) D \rho}{\mu}

where :math:`\mu` is the dynamic viscosity of air. The Schmidt number,
:math:`S_c` is set to 0.6 as discussed earlier.

The integrated value of :math:`CF'` *for spherical particles* over a
generalised gamma distribution of sizes is defined as:

.. math::

   {{\cal V}_x}=2\pi n_{0x}
             \left(0.65\frac{\Gamma(2+\alpha_x)}{\lambda_x^{(2+\alpha_x)}}
                          +0.44\left(\frac{c_x}{\mu}\right)^{\frac{1}{2}}
                                                             S_c^{\frac{1}{3}}
    \rho^{\frac{1}{2}} {\left( \frac{\rho_0}{\rho} \right)}^{\frac{\mathcal{G}_x}{2}}
           \frac{\Gamma\left(0.5d_x+\alpha_x+2.5\right)}
    {\left(\lambda_x+0.5h_x\right)^{(0.5d_x+\alpha_x+2.5)}}
             \right)
   \label{eq:mic_ventx}

:math:`x` can stand for :math:`R`,\ :math:`c`,\ :math:`a` or :math:`g`.
The deposition and sublimation rates of snow aggregates
(:math:`P_{SDEP}` and :math:`P_{SSUB}`) are given by

.. math::

   P_{SDEP} ( or ~ -P_{SSUB})=
        \frac{ \left(\frac{q}{q_{isat}}-1\right)} {\rho \mbox{AB}_{ice}}
   \times {{\cal V}_x}
   \label{eq:mic_xsub}

where :math:`\mbox{AB}_{ice}` is a thermodynamic term given by
:raw-latex:`\cite{Rogers:Yau:1989}` as

.. math::

   \mbox{AB}_{ice}=\left(\frac{L_S}{R_vT}-1\right)\frac{L_S}{K_a(T)T}+\frac{R_v
     T}{e_{isat}\psi(T,p)}
   \label{eq:mic_ABiceUM}

where :math:`e_{isat}` is the saturated vapour pressure over ice. When
liquid exists this is assumed to be removed before the ice (the
Bergeron-Findeisen process: :raw-latex:`\citealp{Bergeron:1935}`), hence
the split into :math:`P_{SDEP1}` and :math:`P_{SDEP2}` terms. The
deposition/sublimation term only acts when :math:`T<0 \deg C`.

**Non-spherical particles**. The above derivation is for spherical
particles (these are used by default but aren’t consistent with the
area-size relationships). For non-spherical particles we can use the
concept of capacitance to provide a multiplying factor to the rate
equation. This gives :raw-latex:`\citep{Rogers:Yau:1989}`:

.. math::

   \begin{aligned}
   c =  \frac{  {\left(1 - \left( {\frac{1}{r_a}} \right)^2 \right) }^{ \frac{1}{2}} }
             {\mathrm{log} \left( r_a + {\left( {r_a}^2 -1 \right)}^{\frac{1}{2}} \right)},
             ~~r_a > 1 (prolates) \\
   c = 1,~~r_a = 1 (spherical) \\
   c = \frac{ {\left( 1 - {r_a}^2 \right)}^{\frac{1}{2}}}
            {\mathrm{sin}^{-1} \left( {\left( 1 - {r_a}^2 \right)}^{\frac{1}{2}} \right) },
             ~~r_a < 1 (oblates) 
   \end{aligned}

where :math:`r_a` is the axial ratio [3]_

:math:`c` is the multiplying factor to apply to :math:`{\cal V}_x`. The
precipitation scheme allows the specification of an axial ratio and make
additional assumptions about the nature of the particle shape; subliming
particles are assumed to have a more rounded shape with more
molecular-scale surface steps on their surface. This means it is more
difficult to deposit ice than sublime it, and accordingly the rate for
depositing ice is multiplied by a factor of 0.9, which is a number used
by Wilson to represent this process.

By default, model assumes all ice crystals to be spherical. To change
the capacitance or shape parameter value for non-spherical particles
(i.e. corresponding to any oblate sphere shape in general, where the
horizontal axes are longer than the vertical axis and more
representative of an aggregate or flat ice crystal), the logical switch,
l, which appears under Ice processes in Section 04 in rose GUI needs to
be set to true.

**With the generic ice particle size distribution** When the generic ice
particle size distribution is switched on, equation
`[eq:mic_xsub] <#eq:mic_xsub>`__ remains identical, but equation
`[eq:mic_ventx] <#eq:mic_ventx>`__ is modified as

.. math::

   {{\cal V}_x}=2\pi\left(0.65 \mathcal{M}_1 + 0.44 
   \left(\frac{c_x}{\upsilon}\right)^{\frac{1}{2}}S_c^{\frac{1}{3}}\rho^{\frac{1}{2}} 
   {\left( \frac{\rho_0}{\rho} \right)}^{ \frac{\mathcal{G}_x}{2}}
   \mathcal{M}_{1+0.5(d_a+1)}\right),
   \label{eq:mic_ventx_psd}

where :math:`\mathcal{M}_1` is the first moment of the generic ice
particle size distribution calculation and
:math:`\mathcal{M}_{1+0.5(da+1)}` is the result of inputting
:math:`1+0.5~(d_a+1)` into the generic ice particle size distribution
calculation.

The multiplying factor, :math:`c`, for non-spherical particles may also
be used to scale the values coming from equation
`[eq:mic_ventx_psd] <#eq:mic_ventx_psd>`__.

**Cloud fraction changes** Deposition is assumed to remove :math:`C_l`
but not to adjust :math:`C_i` or :math:`C`. If we assume a uniform
distribution of liquid water across the liquid cloud partition between
values 0 and :math:`\frac{2 q_{cl}}{C_l}`, and a uniform removal of
liquid water, then we obtain the expression

.. math::

   \Delta C_l = C_l {\left( 1 - \frac{\Delta q_{cl}}{q_{cl}} 
   \right) }^{\frac{1}{2}} - C_l .

Sublimation is assumed to reduce :math:`C_i` but not to alter
:math:`C_l`. A similar argument to that for deposition allows one to
estimate this change as

.. math:: \Delta C_i = C_i { \left( 1 + \frac{\Delta q_{cf}}{q_{cf}} \right) }^{\frac{1}{2}}

and hence a similar adjustment to the total cloud fraction (since
sublimation can only occur outside of liquid cloud).

PIDEP/PISUB: Deposition/Sublimation of vapour on to ice crystals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cfc}`, :math:`q` to :math:`q_{cfc}`.**
This term is identical to the above except the parameters used are those
for the ice crystal category.

Hallett-Mossop process
~~~~~~~~~~~~~~~~~~~~~~

**Formulation in the UM**

There is functionality in the UM to include a simple
:raw-latex:`\cite{Hallett:Mossop:1974}` process that acts to increase
the deposition rate by a factor when supercooled liquid water is
present, although this is not usually turned on in the model. A
gui/namelist switch from VN7.9 allows this option to be turned on if
required.

The deposition rate to ice crystals with the Hallett-Mossop
representation on (:math:`PIDEP_{HM}`) is given by

.. math:: PIDEP_{HM} = PIDEP \left( 1 + f_{HM}(T) \frac{q_{cl}}{q_{cl0}} \right)

where :math:`q_{cl0}` is a reference liquid water content from
:raw-latex:`\citealp{Hallett:Mossop:1974}` (:math:`1.0 \times 10^{-4}`
kg kg\ :math:`^{-1}`) and :math:`f_{HM}` is a function of temperature

.. math::

   \begin{aligned}
   f_{HM} = \frac{1}{HM_{norm}} \left( 1 - \exp \left( \frac{ T - T_{HM2} }{T_{HM3}} 
   \right) \right),~~T_{HM2}>T>T_{HM1} \\
   f_{HM} = \exp \left( \frac{ T - T_{HM1} }{T_{HM3}} \right), ~~T<T_{HM1} \\
   f_{HM} = 0, ~~T>T_{HM2}
   \end{aligned}

where

.. math:: HM_{norm} = 1 - \exp \left( \frac{ T_{HM1} - T_{HM2} }{T_{HM3}} \right).

:math:`T_{HM1}` and :math:`T_{HM2}` are the temperature limits for
producing splinters, the rate varies with number concentration over an
altitude equivalent to a temperature change of :math:`T_{HM3}`. If you
wish to use this representation, you are advised to set
:math:`T_{HM1} = -8~^{\circ}`\ C, :math:`T_{HM2} = -3~^{\circ}`\ C,
:math:`T_{HM5} = 7~^{\circ}`\ C.

PSAUT: Aggregation of ice crystals to snow aggregates 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfc}` to :math:`q_{cfa}`**

**If there is only one ice prognostic**

The schemes have a diagnostic split between ice crystals and aggregates
and therefore do not include an explicit autoconversion term from ice
crystals to aggregates. Instead, the single ice prognostic variable is
split each timestep into crystals and aggregates for the microphysical
processes as described earlier.

**If there are two ice prognostics**

The process of aggregation of ice crystals to snow aggregates is coded
to emulate the diagnostic split scheme, i.e. the amount of ice crystal
mass is calculated using the diagnostic split (equation
`[eq:cry_agg_split] <#eq:cry_agg_split>`__) and any mass greater than
this threshold is transferred to the aggregate category.

.. _`sec:PSACI`:

PSACI: Collection of ice crystals by snow aggregates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfc}` to :math:`q_{cfa}`**. In reality, the transfer process
should be small. This modification only works when the use of a second
ice prognostic (crystals) is used. Collection of ice crystals by snow
does not take place when the generic ice particle size distribution is
turned on.

The rate of collision between the snow and ice crystal categories is
parametrized as a double integration, to take into account the spectrum
of sizes of particles of each category. The general result for the rate
that mass from category :math:`y` is collected by category :math:`x` is

.. math::

   \begin{aligned}
    P_{YACX}=\frac{1}{\rho}
             \int_0^\infty\int_0^\infty E_{xy}\frac{\pi}{4}(D_x+D_y)^2
            | V_x(D_x) - V_y(D_y)|
                            \nonumber \\
             \hspace{0.5cm}M_x(D_x) n_x(D_x) n_y(D_y) dD_x dD_y
   \label{eq:mic_pyacx1}
   \end{aligned}

Where :math:`E_{xy}` is a collection efficiency defined following
:raw-latex:`\cite{Gray:etal:2004}` as

.. math::

   E_{xy}= 0.02 \exp ( 0.08 (T - 273.15))
   \label{eq:mic_exy}

The integration of equation `[eq:mic_pyacx1] <#eq:mic_pyacx1>`__ is made
easier (or indeed possible) by making the assumption of
:raw-latex:`\cite{Forbes:Halliwell:2003}` that

.. math::

   | v_x(D_x) - v_y(D_y) | =\mbox{\footnotesize \sf MAX} \left[(\overline{v_x}+\overline{v_y})/8,| \overline{v_x} 
   - \overline{v_y} |\right]  
   \label{eq:mic_vx_vy}

for all values of :math:`D_x` and :math:`D_y`. So the velocity
difference between any two particles from the two different categories
is assumed to be the difference between the mass–mean fall velocities
:math:`\overline{v_x}` and :math:`\overline{v_y}` or a quarter of the
average of the two mass–mean fall velocities, whichever is greater. The
latter takes account of the distribution of fall speeds in the case
where the mean fall speeds of the two categories are similar.

Substituting in equation (`[eq:mic_vx_vy] <#eq:mic_vx_vy>`__) allows
equation (`[eq:mic_pyacx1] <#eq:mic_pyacx1>`__) to be integrated giving
equation `[eq:mic_pyacx2] <#eq:mic_pyacx2>`__ (where many of the
parameters have been defined earlier in section
`4 <#sec:param_par_char>`__, with default values in tables
`2 <#tab:mic_consts_psd>`__,\ `9 <#tab:mic_consts_density>`__ and
`5 <#tab:mic_consts_fallspeed>`__.) Specifically now for the collection
of ice by snow we have:

.. math::

   \begin{aligned}
    P_{SACI}&=&\frac{\pi}{4\rho} E_{xy}a_a n_{0c}\mbox{\footnotesize \sf MAX} \left[(V_a+V_c)/8,| V_a -V_c |\right]  
             \nonumber \\
            & &\times\int_0^\infty\int_0^\infty (D_a+D_c)^2
             D_a^{b_a}n_a(D_a) n_c(D_c) dD_a dD_c
             \nonumber \\[0.5cm]
              &=&\frac{\pi}{4\rho}E_{xy}a_a n_{0c}\mbox{\footnotesize \sf MAX} \left[(V_a+V_c)/8,| V_a -V_c |\right]  
             \nonumber \\
              & & \times  \int_0^\infty D_a^{b_a} n_a(D_a)
                 \left(D_a^2\frac{\Gamma(1+\alpha_c)}{\lambda_c^{(1+\alpha_c)}}
                      +2D_a\frac{\Gamma(2+\alpha_c)}{\lambda_c^{(2+\alpha_c)}}
                   +\frac{\Gamma(3+\alpha_c)}{\lambda_c^{(3+\alpha_c)}}\right)dD_a
             \nonumber \\[0.5cm]
             &=&\frac{\pi}{4\rho}E_{xy}a_an_{0a}n_{0c}
                                     \mbox{\footnotesize \sf MAX} \left[(V_a+V_c)/8,| V_a -V_c |\right]  
             \nonumber \\
              & &\times
              \left(\frac{\Gamma(1+\alpha_c)}{\lambda_c^{(1+\alpha_c)}}
                    \frac{\Gamma(3+\alpha_a+b_a)}{\lambda_a^{(3+\alpha_a+b_a)}}
                  +2\frac{\Gamma(2+\alpha_c)}{\lambda_c^{(2+\alpha_c)}}
                    \frac{\Gamma(2+\alpha_a+b_a)}{\lambda_a^{(2+\alpha_a+b_a)}}
    \right. \nonumber \\ & & \left. \hspace{1.5cm}
                   +\frac{\Gamma(3+\alpha_c)}{\lambda_c^{(3+\alpha_c)}}
                    \frac{\Gamma(1+\alpha_a+b_a)}{\lambda_a^{(1+\alpha_a+b_a)}}
                                                              \right)
   \label{eq:mic_pyacx2}
   \end{aligned}

.. _`sec:PSACW`:

PSACW: Riming by aggregates
~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cfa}`.**

**When the generic ice particle size distribution is not used**

Although this term is called ’riming’, it obeys a similar process (and
hence is formulated in the same way), as that for the accretion of
liquid cloud by falling rain.

.. math::

   P_{SACW}=\frac{\pi n_{0a} c_a  \Gamma (3+d_a+\alpha_a) E_{aw} q_{cl}}
               {4(\lambda_a+h_a)^{3+d_a+\alpha_a}}
           \left(\frac{\rho_0}{\rho}\right)^{\mathcal{G}_a}
   \label{eq:mic_psacw}

Collision/collection efficiency :math:`E_{aw}` are also assumed to be 1,
which is not such a reasonable assumption for ice particles since they
have slower fall-speeds (see e.g. :raw-latex:`\citealp{Mitchell:1996}`).
No change in the cloud fractions are assumed. This term is only allowed
to act when T\ :math:`< 0 ^{\circ}`\ C.

**When the generic ice particle size distribution is used**

This follows the same form as equation
`[eq:mic_psacw] <#eq:mic_psacw>`__, although with the intercepts
replaced by moment calculations. Equation `[eq:field1] <#eq:field1>`__
is used to calculate the moment of the ice particle size distribution
corresponding to :math:`2+d_a`, :math:`\mathcal{M}_{2+d_a}` and then the
riming equation can be modified as follows:

.. math::

   P_{SACW} = \frac{\pi}{4} c_a \mathcal{M}_{2+d_a} E_{aw} q_{cl}
   \left(\frac{\rho_0}{\rho}\right)^{\mathcal{G}_a}.
   \label{eq:mic_psacw_psd}

**When shape-dependent riming is used**

The default riming parametrization assumes that the ice particles
undergoing collisions are spheres. The parametrization can be modified
to include a power-law dependence of the cross-sectional area on
diameter. The same method is applied for crystals if two ice species are
used. This is implemented via a user-defined cross-sectional area ratio
(the ratio of particle cross-sectional area to that of a sphere with the
same diameter). The cross-sectional area-ratio is given by
:math:`R(D) = a_r D^{b_r}`, the parameters :math:`a_r` and :math:`b_r`
being user-defined inputs. In the code, the actual particle area is
:math:`A = RD^2` (a neglected factor of :math:`4/\pi` being considered
as part of the uncertainity in the collection efficency of ice/liquid
collisions). The default parameters are taken from the analysis of
*insitu* aircraft data by :raw-latex:`\cite{Heymsfield:Milo:2003}`.

Using the shape-dependent riming parametrization also allows for a
threshold liquid-water content for riming to be specified. Only liquid
water contents above this threshold are available for riming. This is
done to mimic the findings of :raw-latex:`\cite{Harimaya:1975}` that
there is a minimum droplet size for riming to occur. To implement the
minimum :math:`q_{cl}` for riming, the implicit solution of the process
rate equation is modified, as described in Section
`7.2 <#sec:proc_rate_implicit>`__.

PIACW: Riming by crystals
~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{cfc}`.** This term is formulated in the
same way as the riming by aggregates term in equation
`[eq:mic_psacw] <#eq:mic_psacw>`__ (and is valid for non-generic ice PSD
cases). The only differences are the values of the parameters used in
the PSD, density and fall speed parametrizations. Collision/collection
efficiency are also assumed to be 1 and no change in cloud fractions
occur.

.. _`sec:PGAUT`:

PGAUT: Autoconversion of snow to graupel
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfa}` to :math:`q_{graup}`.** It is assumed that when snow
growth is dominated by riming liquid cloud it increases its density, so
some is converted to the graupel category. A threshold snow mass
concentration is defined which must be exceeded before this process is
activated. This is for :math:`\rho q_{cfa} >3 \times 10^{-4}` kg
m\ :math:`^{-3}` and also the temperature must be below :math:`-4` C.
This is based on radar observations of a large number of convective
showers over Southern England
:raw-latex:`\citep{Forbes:Halliwell:2003}`. The conversion rate is:

.. math::

   P_{GAUT}= \mathcal{F} \times \mbox{\footnotesize \sf MAX} \left[0, P_{SACW}-P_{SDEP}\right]  .
   \label{eq:mic_pgaut}

where :math:`P_{SACW}` is the rate of riming of snow and
:math:`P_{SDEP}` is the rate of snow deposition. Thus the riming rate of
snow must exceed the rate of growth due to vapour deposition. The
coefficient :math:`\mathcal{F}` is inserted because the riming snow will
not immediately increase its density to that of graupel. For the
original :raw-latex:`\cite{Forbes:Halliwell:2003}` graupel scheme,
:math:`\mathcal{F}` is set to a constant value of 0.5. With the modified
scheme :raw-latex:`\cite{Field:etal:2019}`, the value of
:math:`\mathcal{F}` is set to match the
:raw-latex:`\cite{Thompson:etal:2008}` scheme as follows:

.. math::

   \mathcal{F}=\left\{ \begin{array}{llll}
         0.75  & & \mathcal{R} & > 30 \\
         0.028 (\mathcal{R} -5) + 0.05 & 5 \le & \mathcal{R} & \le 30 \\
         0     & & \mathcal{R} & < 5
       \end{array},\right.
   \label{eq:mic_pgaut_f}

where :math:`\mathcal{R}` is defined as
:math:`\frac{P_{SCAW}}{P_{SDEP}}`.

This has the impact that the initial snow to graupel production within a
cloud cannot start until the ratio of riming to deposition is 5 or more.
With the original graupel scheme, small amounts of graupel were commonly
produced away from the main core of a convective cell; with the
modifications in `[eq:mic_pgaut_f] <#eq:mic_pgaut_f>`__, the graupel
seen within a convective cell tends to be produced closer to the main
core of the storm, which looks more realistic when comparing to radar
observations.

.. _`sec:PGACW`:

PGACW: Riming by graupel
~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{graup}`.** The collection rates of liquid
cloud by graupel obey exactly the same physics as the riming of crystals
and aggregates (equation `[eq:mic_psacw] <#eq:mic_psacw>`__, but with
the parameters for graupel from tables `2 <#tab:mic_consts_psd>`__ and
`5 <#tab:mic_consts_fallspeed>`__ used in place of those for
aggregates).

.. _`sec:PGACS`:

PGACS: Collection of snow aggregates by graupel
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfa}` to :math:`q_{graup}`.** The rates of collision between
the graupel and snow categories is parametrized in the same way as the
snow/crystal collisions (PSACI) described by equation
`[eq:mic_pyacx2] <#eq:mic_pyacx2>`__ in section `6.3.15 <#sec:PSACI>`__,
but with the coefficients for graupel replacing those for snow
aggregates and those for snow aggregates replacing those for ice
crystals. The collection efficiencies remain the same as those used in
equation `[eq:mic_exy] <#eq:mic_exy>`__.

**With the generic ice particle size distribution**

This uses the same physics, but is calculated slightly differently from
`[eq:mic_pyacx2] <#eq:mic_pyacx2>`__ in section `6.3.15 <#sec:PSACI>`__.
Equation `[eq:field1] <#eq:field1>`__ is used to calculate the zeroth
(:math:`\mathcal{M}_0`), first (:math:`\mathcal{M}_1`), second
(:math:`\mathcal{M}_2`) and :math:`b_a+d_a`
(:math:`\mathcal{M}_{b_a+d_a}`) moments of the ice distribution. The
moment :math:`\mathcal{M}_{b_a+d_a}` is used to calculate the ice
particle fall speed, following equation
`[eq:icefallpsd] <#eq:icefallpsd>`__.

Equation `[eq:mic_pyacx2] <#eq:mic_pyacx2>`__ is then modified as
follows:

.. math::

   \begin{aligned}
   P_{GACS}  &=&\frac{\pi}{4\rho}E_{xy}a_gn_{0g}
                                     \mbox{\footnotesize \sf MAX} \left[(\overline{v_g}+\overline{v_a})/8,| 
   \overline{v_g} -\overline{v_a} |\right]  
             \nonumber \\
              & &\times
              \left(\mathcal{M}_0
                    \frac{\Gamma(3+\alpha_g+b_g)}{\lambda_g^{(3+\alpha_g+b_g)}}
                  +2\mathcal{M}_1
                    \frac{\Gamma(2+\alpha_g+b_g)}{\lambda_g^{(2+\alpha_g+b_g)}}
    \right. \nonumber \\ & & \left. \hspace{1.5cm}
                   +\mathcal{M}_2
                    \frac{\Gamma(1+\alpha_g+b_g)}{\lambda_g^{(1+\alpha_g+b_g)}}
                                                              \right)
   \label{eq:pgacs_psd}
   \end{aligned}

**With the increased graupel production option and the improved graupel
representation**

Two options exist to alter the graupel parametrization from the
:raw-latex:`\cite{Forbes:Halliwell:2003}` representation. The first is
an increased production of graupel option where snow-rain collisions are
allowed to create graupel in place of snow. The second is an improved
graupel particle size distribution shown as option (ii) within table
`2 <#tab:mic_consts_psd>`__ and based on the work by
:raw-latex:`\cite{Field:etal:2019}`.

When either of these two options are in use, the :math:`P_{GACS}` term
above defaults to 0.0. This is based on personal communication with
Gregory Thompson (NCAR) who believes that collisions between graupel and
snow particles do not result in any changes in the form of ice.
Therefore, when either of these two options is se, there will be no
change in graupel or snow masses due to the collection of snow
aggregates by graupel.

.. _`sec:PSACR`:

PSACR: Collection of rain by aggregates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{R}` to :math:`q_{cfa}`.** This term uses similar assumptions
as for the collection of ice crystals by snow aggregates above (equation
`[eq:mic_pyacx2] <#eq:mic_pyacx2>`__ in section
`6.3.15 <#sec:PSACI>`__). Again, the approximation

.. math::

   f_V = \mbox{\footnotesize \sf MAX} \left[| \overline{v_a} - \overline{v_R} |,  \frac{ \overline{v_a} + 
   \overline{v_R} }{8}~\right]

is used and the collision and collection coefficients are now assumed to
be 1. Integrating leads to terms in :math:`\lambda_R` and
:math:`\lambda_a` which can then be solved:

.. math::

   \begin{aligned}
   P_{SACR}& =& 
   \frac { \pi^{2} \rho_w f_V } {24 \rho } n_{aa} \lambda_a^{n_{ba}} n_{aR} 
   \lambda_R^{n_{bR}} \nonumber \\
   & & \times
   \left(\frac{\Gamma(3+\alpha_a) \Gamma(4+\alpha_R)} 
   {\lambda_a^{3+\alpha_a} \lambda_R^{4+\alpha_R}}
   + \frac{ 2 \Gamma(2+\alpha_a) \Gamma(5+\alpha_R) } 
   {\lambda_a^{2+\alpha_a} \lambda_R^{5+\alpha_R}} \right. \nonumber \\
   & & \left. \hspace{1.5cm}+ \frac{\Gamma(1+\alpha_a) 
   \Gamma(6+\alpha_R)} { \lambda_a^{1+\alpha_a} \lambda_R^{6+\alpha_R} }
   \right)
   \label{eq:psacr}
   \end{aligned}

Note that equation `[eq:psacr] <#eq:psacr>`__ is formulated slightly
differently than equation `[eq:mic_pyacx2] <#eq:mic_pyacx2>`__ due to
the captured quantity being water and not ice.

**When the increased graupel production term is included** The resultant
of the collision/collection :math:`P_{SACR}` can either be aggregates or
graupel. Collisions that produce graupel are noted :math:`P_{SACR-G}`
whilst those which produce aggregates are noted :math:`P_{SACR-A}`. If
the increased graupel production scheme (allowing snow-rain collisions
to produce graupel) is switched off, then the collision will not produce
any graupel (i.e. the result is always :math:`P_{SACR-A}`).

If the scheme is switched on, then collisions between aggregates and
rain will always produce graupel.

**Aside:** Note that a different sub-routine is used dependent on
whether the collection/captured quantity is between rain and ice.
*lsp_collection.F90* is used for ice-ice processes, *lsp_capture.F90* is
for ice-liquid processes and liquid-liquid (accretion) is in
*lsp_accretion.F90*.

There is no update to the rain fraction :math:`C_R` from this process.
However, in the event that collection of rain reduces qrain to zero,
checks later in the microphysics scheme will reset the rain fraction to
zero.

If using the prognostic precipitation fraction, the change of rain
fraction is calculated differently; see section
`5.4.3.1 <#sec:precip_frac_update>`__.

There are no changes to the cloud fractions as a result of this process.

**When the generic ice particle size distribution is used**

This is calculated in a similar way to section `6.3.20 <#sec:PGACS>`__.
Equation `[eq:field1] <#eq:field1>`__ is used to calculate the zeroth
(:math:`\mathcal{M}_0`), first (:math:`\mathcal{M}_1`), second
(:math:`\mathcal{M}_2`), :math:`1+0.5(d_a+1)`
(:math:`\mathcal{M}_{1+0.5(d_a+1)}`) and :math:`b_a+d_a`
(:math:`\mathcal{M}_{b_a+d_a}`) moments of the ice distribution. The
moment :math:`\mathcal{M}_{b_a+d_a}` is used to calculate the ice
aggregate fall speed, following equation
`[eq:icefallpsd] <#eq:icefallpsd>`__.

Equation `[eq:psacr] <#eq:psacr>`__ can be modified as follows

.. math::

   \begin{aligned}
   P_{SACR}& =& \frac { \pi^{2} \rho_w f_V } {24 \rho }  n_{aR} \lambda_R^{n_{bR}} 
   \nonumber \\
   & & \times
   \left(\frac{\mathcal{M}_2 \Gamma(4+\alpha_R)} {\lambda_R^{4+\alpha_R}}
   + \frac{ 2 \mathcal{M}_1 \Gamma(5+\alpha_R) } {\lambda_R^{5+\alpha_R}} \right. 
   \nonumber \\
   & & \left. \hspace{1.5cm}+ \frac{\mathcal{M}_0 \Gamma(6+\alpha_R)}
   {\lambda_R^{6+\alpha_R} } \right)
   \label{eq:psacr_psd}
   \end{aligned}

where, as usual the moments replace the aggregate terms.

When the generic ice particle size distribution is used in conjunction
with the increased graupel production scheme (allowing snow-rain
collisions to produce graupel) then a different approach must be used
due to the lack of an ice crystal category. This is done by comparing
the mean diameters of each of the species involved in the collision.

For rain, we can derive the mass-mean diameter as

.. math::

   \begin{aligned}
   \label{rain:mmd}
   \bar{D_R}& = & \frac{\int_0^{\infty} n_{aR} \lambda_R^{n_{bR}} \frac{\pi}{6} \rho_w D_R^3 
   \exp(-\lambda_R D) D dD }
   {\int_0^{\infty} n_{aR} \lambda_R^{n_{bR}} \frac{\pi}{6} \rho_w D_R^3 
   \exp(-\lambda_R D) dD } \nonumber \\
            & = & \frac{\int_0^{\infty} D^4 \exp(-\lambda D) dD }
                       {\int_0^{\infty} D^3 \exp(-\lambda D) dD } \nonumber \\
            & = & \frac{\Gamma(5)}{\lambda_R^5} \frac{\lambda_R^4}{\Gamma(4)} \nonumber \\
            & = & \frac{4}{\lambda_R} 
   \end{aligned}

The value of :math:`\lambda_R` can then be derived as in section
`4.6 <#mr2psd>`__. A similar approach can be used to define
4.0/:math:`\lambda_R` for aggregates. This is simply as follows

.. math::

   \begin{aligned}
   \label{ice:mmd}
   \bar{D_a}& = & \frac{4}{\lambda_a}\nonumber \\
            & = & \frac{\mathcal{M}_{ba + 1}}{\mathcal{M}_{ba}}
   \end{aligned}

where equation `[eq:field1] <#eq:field1>`__ is used to calculate the two
moments required. If :math:`\bar{D_R}` is greater than :math:`\bar{D_a}`
then the result of a collision is a graupel particle. Otherwise the
result will be an ice aggregate.

PIACR: Collection of rain by crystals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{R}` to :math:`q_{cfc}`.** This term is formulated in the
same way as the collection of rain by aggregates term (PSACR; equation
`[eq:psacr] <#eq:psacr>`__ in section `6.3.21 <#sec:PSACR>`__). The only
differences are the values of the parameters used to describe the
properties of the crystals.

**With the increased graupel production option** Collisions between
crystals and rain will produce graupel (:math:`P_{IACR-G}`) if the rain
mixing ratio is 0.1 g kg\ :math:`^{-1}` or above. Below this threshold
the result of the collision will be crystals (:math:`P_{IACR-C}`).

PSMLTEV: Evaporation of melting snow aggregates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfa}` to :math:`q`.** This term acts to evaporate any ice at
temperatures above 0C since the deposition term is switched off at these
temperatures. The term follows that for the deposition/sublimation
process equation with the exception that saturation vapour pressures and
latent heats in the calculation of the evaporation rate are used for
liquid, not ice. However, the latent heat of sublimation is used to
calculate the temperature change due to the evaporation. Either the
default ‘intercepts’ method or the generic ice particle size
distribution can be used with this option; the formulation is the same
as in section `6.3.11 <#sec:psdep_pssub>`__.

PIMLTEV: Evaporation of melting ice crystals
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfc}` to :math:`q`.** This term is parametrized in the same
way as for aggregates, simply with the crystal parameters instead of the
aggregate values.

PSMLT: Melting of snow aggregates to rain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfa}` to :math:`q_R`.** This is solved from the diffusion
equation. The latent heat due to melting is equal to the sum of the
sensible heat lost due to thermal diffusion and convection and the
latent heat due to vapour transfer:

.. math::

   L_f \frac {dM_{melt}}{dt}=-2\pi D K_a T_c F'
                      +2\pi D L_v \psi \rho (q - q_{0sat}) F'

Here, :math:`q_{0sat}` is the saturation mixing ratio at 0
:math:`^{\circ}`\ C. Integrating over all particle diameters, and
ignoring corrections due to the sensible heat associated with accreted
liquid water, the melting of snow to form rain is given as:

.. math::

   P_{SMLT} ~=~
   \frac{1}{\rho L_f} (K_a(T-T_0)-L_v\psi\rho(q -q_{0sat}))\times{\cal V}_a
   \label{eq:mic_psmlt}

where :math:`T_0` is 0C. The ventilation coefficient is given in
equation `[eq:mic_ventx] <#eq:mic_ventx>`__. The second term can be
subsumed into the first if we use the wet-bulb temperature, :math:`T_w`,
in the calculation. Damian Wilson approximated the wet bulb temperature
over a range of temperatures and pressures as

.. math::

   T_w-T_0 = T - T_0 + \left( q_{wsat} - q \right) \times
   \left(\mathcal{N}_1 + \mathcal{N}_2 (p - \mathcal{N}_3)
    - \mathcal{N}_5 (T - \mathcal{N}_6) \right) .

where :math:`\mathcal{N}_1= 1329.31` K, :math:`\mathcal{N}_2=0.0074615`
K m\ :math:`^2` N\ :math:`^{-1}`,
:math:`\mathcal{N}_3= 0.85 \times 10^5` N m\ :math:`^{-2}`,
:math:`\mathcal{N}_5= 40.637` and :math:`\mathcal{N}_6=275`\ K. The
variable :math:`q_{wsat}` is the saturation mixing ratio with respect to
liquid water.

The value of :math:`T_w` used in the calculation is weighted by the size
of the ice-only and the mixed-phase partitions in the gridbox. The rain
fraction is increased to :math:`C_i` if :math:`C_i` is larger than the
rain fraction. If using the prognostic precipitation fraction, the
change of rain fraction is calculated differently; see section
`5.4.3.1 <#sec:precip_frac_update>`__. The scheme reduces the
:math:`C_i` in proportion to the mass of ice melted:

.. math:: \Delta C_i = P_{SMLT} \frac{C_i}{q_{cfa}}

and reduces :math:`C` assuming that the changes to :math:`C_i` are
randomly overlapped with any existing liquid cloud.

**Using the generic ice particle size distribution**

This follows the intercept method, although with the ventilation
coefficient as defined in equation
`[eq:mic_ventx_psd] <#eq:mic_ventx_psd>`__.

PIMLT: Melting of ice crystals to rain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cfc}` to :math:`q_{R}`.** This term is equivalent to the
melting of aggregates to rain, although with different parameter values.

.. _`sec:PGMLT`:

PGMLT: Melting of Graupel
~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{graup}` to :math:`q_{R}`.** The melting of graupel acts as a
source of rain and is parametrized in the same way as the melting of
snow to form rain in the UM:

.. math::

   P_{GMLT} =
   \frac{1}{\rho L_f} K_a(T_w-T_0) \times{\cal V}_g ,

where :math:`L_f` is the latent heat of fusion, :math:`K_a` is the
thermal conductivity, :math:`(T_w-T_0)` is the difference between the
wet-bulb temperature of the air and 0C and :math:`{\cal V}_g` is the
integrated ventilation factor for spherical particles with a generalised
gamma distribution of particle sizes:

.. math::

   {{\cal V}_g}=2\pi n_{0g}
             \left(0.78\frac{\Gamma(2+\alpha_g)}{\lambda_g^{(2+\alpha_g)}}
                          +0.31\left(\frac{c_g}{\mu}\right)^{\frac{1}{2}}
                                                             S_c^{\frac{1}{3}}
            \rho^{\frac{1}{2}}\left(\frac{\rho}{\rho_0}\right)^{\frac{\mathcal{G}_g}{2}}
           \frac{\Gamma\left(0.5d_g+\alpha_g+2.5\right)}
    {\left(\lambda_g+0.5h_g\right)^{(0.5d_g+\alpha_g+2.5)}}
             \right).
   \label{eq:mic_ventx_g}

It should be noted that the ventilation coefficients used here, (0.78
and 0.31) are the same as rain and not ice. This method is used
elsewhere in the literature (e.g.
:raw-latex:`\citealp{Reisner:etal:1998}` ) and tries to implement the
fact that graupel particles are spheres with a much higher density than
aggregates, and are more like raindrops in nature than they are like
aggregates.

.. _`sec:PREVP`:

PREVP: Evaporation of rain
~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{R}` to :math:`q`.** The evaporation rate of rain is
analogous to the sublimation of snow in equation
(`[eq:mic_xsub] <#eq:mic_xsub>`__) and only occurs in sub-saturated air.

.. math::

   P_{REVP}=
        \frac{ \left(\frac{q}{q_{wsat}}-1\right)} {\rho \mbox{AB}_{liq}}
   \times {{\cal V}_r}

where :math:`\mbox{AB}_{liq}` is the thermodynamic coefficient
appropriate for liquid drops and is given by,

.. math::

   \mbox{AB}_{liq}=   \left(  \frac{L_v}{R_v T} -1 \right) 
   \frac{L_v}{K_a T} + \frac{R_v T}{\psi e_{sat~liq}}.
   \label{eq:mic_ABliq}

There are a few differences to the sublimation term. The ventilation
factor is different, in this term we use the
:raw-latex:`\cite{Beard:Pruppacher:1971}` formulation:

.. math:: F'=0.78+0.31S_c^{\frac{1}{3}} R_e^\frac{1}{2}

where the Schmidt number, :math:`S_c`, is again approximated to the
value 0.6. The particles are also assumed to be spherical in the
capacitance calculation.

Note that if the user has diagnostic rain selected and the
:raw-latex:`\cite{Abel:Shipway:2007}` rain fall speeds selected, the
evaporation rate will be enhanced for light rain rates, in an attempt to
remove some of the spurious drizzle from the model. See section
`4.4.3 <#sec:as07>`__ for more details.

Usually this process does not alter the rain fraction :math:`C_R`;
except that :math:`C_R` is reset to zero in the event that qrain falls
below a minimum allowed value, below-which it is forced to evaporate
completely.

If using the prognostic precipitation fraction, the change of rain
fraction is calculated differently; see section
`5.4.3.1 <#sec:precip_frac_update>`__.

There are no cloud fraction changes associated with this term.

.. _`sec:PRACW`:

PRACW: Accretion of cloud liquid water by rain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{R}`.** The rate that liquid cloud is
collected by rain is the product of the sweep out rate of rain, the mass
concentration of liquid cloud and the efficiency that liquid cloud
droplets collide with and then coalesce with raindrops that intercept
them on their direct fall line. This is formulated as:

.. math::

   P_{RACW}=\frac{\pi n_{0r} c_r  \Gamma (3+d_r+\alpha_R) E_{rw} {q_{cl}}}
               {4(\lambda_R+h_R)^{3+d_r+\alpha_R}}
           \left(\frac{\rho_0}{\rho}\right)^{\mathcal{G}_R}
    \label{eq:mic_pracw}

We assume that the collision/collection efficiency is 1. There is
assumed to be no change in rain fraction and no change in cloud
fractions.

**Under the improved warm rain scheme**, this process rate is replaced
by the formulation of :raw-latex:`\cite{Khair:Kogan:2000}`, bias
corrected following :raw-latex:`\cite{boutle:etal:2014}`. Therefore, the
process rate is given by:

.. math:: P_{RACW} = 67E(f_{cl},f_R,\rho)q_{cl}^{1.15}q_R^{1.15},

where

.. math::

   \begin{aligned}
   E(f_{cl},f_R,\rho)=\qquad\qquad\qquad\qquad\nonumber\\
   (1+f_{cl}^2)^{-1.15/2}(1+f_{cl}^2)^{1.15^2/2}\nonumber\\
   \times (1+f_R^2)^{-1.15/2}(1+f_R^2)^{1.15^2/2}\nonumber\\
   \times \exp\left(\rho 1.15^2 \sqrt{\ln(1+f_{cl}^2)\ln(1+f_R^2)}\right),
   \end{aligned}

.. math::

   \label{eq-fsdqcl}
     f_{cl}=\left\{ \begin{array}{ll}
         (0.45-0.25C_l)\sqrt{(xC_l)^{2/3}}((0.06xC_l)^{1.5}+1)^{-0.17}&C_l<1 \\
         0.11\sqrt{(xC_l)^{2/3}}((0.06xC_l)^{1.5}+1)^{-0.17}&C_l=1
       \end{array},\right.

and

.. math::

   \label{eq-fsdqr}
     f_R=\left\{ \begin{array}{ll}
         (1.1-0.8C_R)\sqrt{(xC_R)^{2/3}}((0.11xC_R)^{1.14}+1)^{-0.22}&C_R<1 \\
         0.3\sqrt{(xC_R)^{2/3}}((0.11xC_R)^{1.14}+1)^{-0.22}&C_R=1
       \end{array},\right.

and :math:`\rho=0.9` is specified.

.. _`sec:PRAUT`:

PRAUT: Autoconversion of cloud liquid water to rain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**:math:`q_{cl}` to :math:`q_{R}`.** The UM has a power-law formulation
of autoconversion as a function of liquid water content with a minimum
threshold liquid water content.

The conversion rate is based on that specified by
:raw-latex:`\cite{Tripoli:Cotton:1980}`:

.. math:: P_{RAUT}=A_1 E_{auto} (\rho q_{cl})^{A_2-1} \frac{q_{cl}}{ (n_d)^{A_3}}

where :math:`n_d` is the number of water droplets and
:math:`E_{auto}=0.55` represents a collision/collection coefficient. The
parameter :math:`A_1` is defined as

.. math::

   A_1 = \frac{4 \pi g}{18 {\left(\frac{4}{3} \pi \right)}^{\frac{4}{3}} 
   \mu {\rho_{w}}^{\frac{1}{3}}}

which has the numerical value 5907.24 at :math:`0^{\circ}`\ C. The other
parameters have the values :math:`A_2 = \frac{7}{3}` and
:math:`A_3=\frac{1}{3}`

There is a minimum liquid water mixing ratio threshold, :math:`q_{cl0}`
(units of kg kg\ :math:`^{-1}`), for autoconversion to occur.

**Default Scheme:** :math:`q_{cl0}` is defined as the liquid water
content such that the number concentration of particles of radii 20
:math:`\mu`\ m or larger is 1000 m\ :math:`^{-3}`. The number of
droplets of radius greater than :math:`r` (:math:`n_r`) can be estimated
assuming a modified gamma cloud droplet distribution
:raw-latex:`\citep{pruppacher:klett}` and then integrating from r to
infinity:

.. math::

   n_r = \left(\frac{A}{B}\right) r^2 e^{-Br} + \frac{2A}{B^2} r e^{-Br} 
   + \frac{2A}{B^3} e ^{-Br}

where :math:`A = \frac{B^3 n_d}{2}`, :math:`B=\frac{3}{r_{mean}}` and
:math:`r_{mean}= {\left( \frac{27 \rho q_{cl}}{80 \pi \rho_{w} n_d} \right)}^{\frac{1}{3}}`

This can be inverted for a threshold radius of 20 :math:`\mu`\ m and a
threshold concentration of 1000 m\ :math:`^{-3}` using the following
numerical approximation (from Andy Jones):

.. math::

   \begin{aligned}
   \label{eq:jones_nd}
   q_{cl0} &=& \frac{1}{\rho} \left(6.20\times10^{-31} n_d^3 - 5.53\times10^{-22} n_d^2 
   \right. 
   \nonumber \\
   & & \left. + ~4.54\times10^{-13} n_d + 3.71\times10^{-6} - \frac{7.59}{n_d} \right)
   \end{aligned}

where :math:`n_d` is in units of m\ :math:`^{-3}`. The value of
:math:`n_d` is determined in section `6.2 <#sec:cloud_drop_calc>`__.

**:raw-latex:`\cite{Tripoli:Cotton:1980}` autoconversion threshold:**
:math:`q_{cl0}` is defined as

.. math::

   \label{eq:tc_act}
   q_{cl0} = \frac{4}{3} \pi \frac{\rho_{w} r^3_{crit} n_d}{\rho}

where :math:`r_{crit} = 7 \times 10^{-6}` m and :math:`n_d` is defined
in section `6.2 <#sec:cloud_drop_calc>`__; this was the only option
available in the now-retired 3B scheme.

With both the default, and Tripoli and Cotton autoconversion thresholds,
autoconversion will not reduce the liquid water content to below the
value of :math:`q_{cl0}`.

**Under the improved warm rain scheme**, this process rate is replaced
by the formulation of :raw-latex:`\cite{Khair:Kogan:2000}`, bias
corrected following :raw-latex:`\cite{boutle:etal:2014}`. Therefore, the
process rate is given by:

.. math:: P_{RAUT}=1350E(f_{cl})q_c^{2.47}N_c^{-1.79},

where

.. math:: E(f_{cl})=(1+f_{cl}^2)^{-2.47/2}(1+f_{cl}^2)^{2.47^2/2},

and :math:`f_{cl}` is given in Equation `[eq-fsdqcl] <#eq-fsdqcl>`__.

.. container:: float
   :name: fig:fall_speeds

   .. container:: center

**Cloud and rain fractions**. The rain fraction is increased to
:math:`C_l` if :math:`C_l` is greater than the current rain fraction. If
using the prognostic precipitation fraction, the change of rain fraction
is calculated differently; see section
`5.4.3.1 <#sec:precip_frac_update>`__.

The cloud fractions are not altered by this microphysical process.

.. _`sec:scav`:

Scavenging of aerosol
~~~~~~~~~~~~~~~~~~~~~

In addition to the link between MURK aerosol and cloud droplet number
concentration described in section `6.3.30 <#sec:PRAUT>`__, falling
precipitation particles can remove aerosol (sometimes called
scavenging). Rain-out of most aerosol species is covered in the
appropriate documentation (:umdp:‘020‘). However, in the case of MURK
aerosol, this follows the method of :raw-latex:`\cite{Clark:etal:2008}`,
and the mixing ratio of aerosol, :math:`A_{mass}` is reduced as:

.. math::

   \label{eq:scav}
   \frac{A_{mass}}{1.0+K_{rain}RR+K_{snow}SR+K_{ds}PLSET}

Where :math:`RR` is the rain rate, :math:`SR` is the snow rate and
:math:`PLSET` is the droplet settle rate. The other coefficients can be
described as

.. math::

   \label{eq:scav_coef}
   K_{rain}=K_{snow}=K_{ds}=1.0\times10^{-4}\times 3600 \times \Delta t.

Numerical methods
=================

This section briefly describes some of the numerical methods that are
used in the solution of the transfer equations.

Fall of ice
-----------

The fall of ice is a particular problem to a microphysics scheme. The
model levels are close together near the surface (less than 100 m apart)
and the timestep may be (in the climate model) as much as 30 minutes.
This means that ice should be able to fall through several model levels
in one timestep.

To solve this we look at the rate of change of ice mass (in either the
‘crystals’ or the ‘aggregates’ category) contained in a layer:

.. math::

   \rho \Delta z \frac{\partial q_{cfx}}{\partial t} ~=~ S_x - 
   \overline{v_{1x}} ~\rho~ q_{cfx}

where :math:`\overline{v_{1x}}` is the mean ice fall speed out of the
layer and :math:`S_x` is the snowfall rate into the layer. If we assume
that :math:`S_x` and :math:`\overline{v_{1x}}` are continuous with time
(which is true in a steady state) we can solve this equation as:

.. math:: q_{cfx}(t+\Delta t) = \frac{S_x}{\rho \overline{v_{1x}}} (1 - a) + q_{cfx}(t) a

where :math:`a` is given by

.. math:: a = \exp \left( - \frac{\overline{v_{1x}} \Delta t}{\Delta z} \right) .

| By conservation of ice mass we can deduce that the snowfall rate out
  of the layer
| ( :math:`S_x(z-\Delta z)` ) can be written as:

.. math::

   S_x(z-\Delta z) = S_x(z) - \left( q_{cfx}(t+\Delta t) - q_{cfx}(t) \right) 
   \frac{ \rho \Delta z}{\Delta t}

which gives a solution

.. math::

   S_x(z-\Delta z) = S_x(z) + \frac{\Delta z}{\Delta t} \left( q_{cfx} \rho
   - \frac{S_x(z)}{\overline{v_{1x}}} \right) \left( 1 - a \right) .

This solution will have numerical difficulties if we define
:math:`\overline{v_{1x}}` as the mean fall-speed of the ice that starts
in a particular layer and :math:`q_{cfx}` in this layer is zero.
Accordingly we define :math:`\overline{v_{1x}}` as an average of the
fall speed in the layer and that of :math:`\overline{v_{1x}}` from the
layer above:

.. math::

   \overline{v_{1x}}(z) = \frac{ \overline{v_{x}} q_{cfx} + 
   \overline{v_{1x}}(z+\Delta z) S_x \frac{\Delta z}{\rho \Delta t} } {q_{cfx} + 
   S_x \frac{\Delta z}{\rho \Delta t}  } .

Since we only store one snowfall flux and one value of
:math:`\overline{v_{1}}` from layer to layer, we average
:math:`\overline{v_{1a}}(z)` and :math:`\overline{v_{1c}}(z)` according
to the relative mass fractions of aggregates and crystals. Similarly,
:math:`S_a` and :math:`S_c` are apportioned from :math:`S` using the
same mass fraction.

The formulation introduces a significant amount of numerical dispersion
when a single ‘block’ of ice is advected downwards. Although this is not
desirable from a numerical point of view (a semi-Lagrangian scheme may
be better, although more expensive to implement), Forbes has shown that
the amount of dispersion is fortuitously similar to the amount of
physical dispersion that should occur because of the distribution of ice
particle sizes (and hence fall speeds).

.. _`sec:proc_rate_implicit`:

Implicit formulation
--------------------

Certain transfer terms, notably those whose rates are proportional to
the amount of a particular variable, can be solved with an implicit
timestep, rather than an explicit one. One example is the riming term.
This can be simplified to the general form:

.. math:: \frac{\partial q_{cl}}{\partial t} ~=~ - k~q_{cl}

where :math:`k` can be considered a constant (it actually depends on the
ice content etc.). The exact solution would take the form of an
exponential decay. The explicit solution is:

.. math:: q_{cl} (t+\Delta t) ~=~ q_{cl} (t)( 1~-~ k \Delta t)

which would be a reasonable solution if :math:`q_{cl}` is being
continuously replenished by another process (this cannot be guaranteed,
though). The implicit solution which is used in the code is to
approximate the solution as:

.. math:: q_{cl} (t+\Delta t) ~=~ q_{cl} (t) \frac{1}{1 ~+~ k \Delta t}

which will not allow :math:`q_{cl}` to go negative. A first order
binomial expansion of the implicit solution will retrieve the explicit
solution.

Other terms which are formulated implicitly include the melting term.
Here, the rate is proportional to the temperature difference between the
wet-bulb temperature and the melting point of ice, and this forms the
implicit part of the calculation. Not all the transfer terms are coded
in an implicit formulation, so the advantages of this formulation are
likely to be limited.

**Implicit solution for riming with :math:`q_{cl}`-threshold**

When the shape-dependent riming with liquid water content threshold
(Section `6.3.16 <#sec:PSACW>`__) is used, the implicit solution needs
to be modifed to account for the minimum :math:`q_{cl}` available for
riming. If the :math:`q_{cl}` threshold is :math:`q_{cl,min}` then the
implicit solution is

.. math:: q_{cl} (t+\Delta t) ~= \min \left\{ q_{cl}(t), \frac{q_{cl}(t)+k\Delta t q_{cl,min}}{1+k\Delta t} \right\}.

Sequential solution of process transfers
----------------------------------------

The transfer processes are calculated sequentially in the model. The
sequential updating allows easier coding of limit relationships when two
or more processes compete for water in the same category. For larger
timesteps the sequence is important (although placing transfers in
parallel does not guarantee less timestep sensitivity). Where
applicable, in the sequences described below, the transfer for the
‘crystals’ is performed before the transfer for the ‘aggregates’.

.. _`sec:historic_order`:

Historic order of transfer processes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

| The historic order in which the transfer processes are applied is as
  follows:
| Droplet settling, Fall of ice, rain and graupel, Homogeneous
  nucleation, Heterogeneous nucleation, Deposition / Sublimation,
  Aggregation, Crystal collection by aggregates, Riming, Graupel
  autoconversion, Graupel Riming, Graupel collection, Capture,
  Evaporation of melting snow, Melting, Evaporation of rain, Accretion,
  Autoconversion.

The location of the sedimentation at the start of the microphysics was
chosen because early investigations suggested that having the
sublimation term later in the microphysics allows ice to evaporate on a
reasonable depth scale.

.. _`sec:sed_at_end`:

Sedimentation at end of the microphysics
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Later, investigations using prognostic rain have shown that the fall of
rain being at the start of the timestep has caused problems. This is
because the melting term occurs after the sedimentation, leading to a
collection of stagnant rain at the melting level, which cannot fall any
further until the next call to the microphysics. This stagnant rain
leads to a large radar reflectivity signal at the melting level which
looks unrealistic compared to observations [4]_. In addition, the
stagnant rain at the end of the timestep is passed to the UM’s dynamical
core and in the presence of an updraught, will be advected back above
the freezing level, leading to supercooled rain, which may persist to
very low temperatures.

To try and avoid these issues, new options are now available to re-order
the transfer processes using the option *sediment_loc*. These are as
follows:

#. As the historical order in section `7.3.1 <#sec:historic_order>`__.

#. As 1., but with the fall of ice, rain and graupel moved after
   autoconversion.

#. As 1., but with the droplet settling and fall of ice, rain and
   graupel moved after autoconversion.

#. As 1., but with the fall of rain moved after autoconversion. Fall of
   ice and graupel remain as the historic order in section
   `7.3.1 <#sec:historic_order>`__.

#. As 4., but with the droplet settling moved between the autoconversion
   term and the fall of rain term.

It is recognised that moving the droplet settling and sedimentation
terms after the autoconversion and accretion terms may have a
significant impact on fog forecasts in the UM. Therefore, the order of
terms within the microphysics scheme remains a current area of research.

.. _`sec:proc_fluxes`:

Applying process rates to hydrometeor fall-fluxes.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ordering of processes detailed in section
`7.3.1 <#sec:historic_order>`__ can be summarised as:

#. Add fall-in of precip flux from the level above.

#. Subtract fall-out of precip flux to the level below.

#. Various process rates applied to the mass of hydrometeors remaining
   on the current model-level (autoconversion, accretion, riming,
   evaporation, vapour-deposition, etc).

#. Tidy-up.

This ordering of processes means that rain, graupel, snow etc can fall
*through* a model-level *before* any of the process rates are applied
(the fall-out flux calculated at stage (2) above cannot be modified by
any of the subsequent processes, such as rain evaporation). This leads
to various numerical problems when the process rates are sufficient to
remove all of the hydrometeor mass remaining on the current level (so
that the process increments get truncated to avoid creating negative
precip mass); they should really have been allowed to remove some of the
flux passed down to the next level as well. For example, this makes it
impossible for the rain flux to evaporate entirely before reaching the
surface (since some rain flux is always passed down to the next level
*before* rain evaporation is applied)  [5]_.

This numerical problem causes light rain rates to spuriously reach the
surface in situations where they should have fully evaporated on the way
down. It also causes small graupel fluxes to spuriously reach the
surface even in very hot weather. There is also a nasty timestep
sensitivity (the longer the timestep, the greater the proportion of the
rain, graupel, etc flux that falls *through* rather than remaining on
the current model-level, and so the less of it can evaporate or melt).

This problem was clearly already recognised for the process of melting
snow (it would have resulted in spurious snowfall at the surface),
because in the "tidy-up" section at the end of the microphysics scheme,
melting is separately applied to the fall-out flux of snow to prevent
this (see section `7.4 <#sec:num_check>`__)

Note that the various options to perform sedimentation for some
variables at the end of the timestep instead of at the beginning
(section `7.3.2 <#sec:sed_at_end>`__) do not address this problem,
because in all cases the increments due to the fall-in and fall-out
fluxes of a given hydrometeor are added in the same place; none of the
options allow other processes to modify the fall-out flux.

We have now implemented a simpler fix for this problem, which is
activated if the UM namelist switch *l_proc_fluxes* is set to true.
After the sedimentation is performed, the fall-out fluxes of ice, rain
and graupel are added back onto the hydrometeor masses at model-level k
(following the conservative flux to mixing-ratio conversion described in
section `2.6 <#sec:flux_to_m>`__):

.. math:: {q_X}_* = q_X + \frac{\Delta t}{\rho \Delta z} f_X

where :math:`q_X` is the mixing-ratio of hydrometeor species :math:`X`
after the initial sedimentation calculation (which does both fall-in and
fall-out), and :math:`f_X` is the fall-flux of hydrometeor :math:`X` out
of the current level (kg m\ :math:`^{-2}` s\ :math:`^{-1}`).

All the other process rates may then act upon the total hydrometeor mass
:math:`{q_X}_*` falling *through* the current model-level. The fall-out
flux is then recalculated at the end such that the *fraction* of
hydrometeor mass falling out of the current level is preserved:

.. math::

   {F_X}_{nf} = \frac{q_X}{{q_X}_*}
      = \frac{q_X}{q_X + \frac{\Delta t}{\rho \Delta z} f_X}

.. math:: {q_X}_{fin} = \left( {q_X}_* + \Sigma dq_X \right) {F_X}_{nf}

.. math::

   {f_X}_{fin} = \frac{\rho \Delta z}{\Delta t}
     \left( {q_X}_* + \Sigma dq_X \right) \left( 1 - {F_X}_{nf} \right)

where :math:`{F_X}_{nf}` is the fraction of hydrometeor mass that is
*not* falling out, :math:`\Sigma dq_X` is the sum of process rate
increments modifying the hydrometeor mass, :math:`{q_X}_{fin}` is the
final mixing-ratio of hydrometeor remaining on the current level, and
:math:`{f_X}_{fin}` is the final corrected fall-out flux accounting for
the change in hydrometeor mass by the process rates.

This way, if a process removes all of the mass of some hydrometeor
species (:math:`{q_X}_* + \Sigma dq_X = 0`) then its fall-out flux will
also go to zero.

This means that the hydrometeor masses :math:`{q_{cf}}_*`,
:math:`{q_{rain}}_*`, :math:`{q_{graup}}_*` passed into the various
process rate calculations become numerical, rather than physical
quantities (since the mass falling through the current model-level
scales with the timestep length). To avoid the resulting timestep
sensitivity, we pass around the fraction of each species’ mass
:math:`{F_X}_{nf}` that is *not* falling out during this timestep;
mutliplying each :math:`{q_X}_*` by :math:`{F_X}_{nf}` recovers the
hydrometeor mass we would have had after the full sedimentation
calculation, as before. Then, every time :math:`{q_X}_*` is used in a
process rate formula (e.g. to compute moments of a particle size
distribution), it is first multiplied by :math:`{F_X}_{nf}`, yielding
the latest-guess value *after* sedimentation.

With this option active (*l_proc_fluxes = .true.*), the snow melting
process no longer needs to be separately applied to the snow fluxes as
described in section `7.4 <#sec:num_check>`__ (doing so would now be
double-counting), so the section of code to do "emergency melting" is
skipped.

.. _`sec:num_check`:

Numerical checks
----------------

The transfers are followed by two numerical checks to remove small ice
contents when they are not growing significantly. The first check is on
:math:`q_{cf}`. This is evaporated back to vapour if the first condition
(1) is true *and any* of the subsequent conditions (2, 3 or 4) are true:

#. | :math:`q_{cf} < q_{cfmin}`

#. | :math:`~T > 0^{\circ}`\ C

#. | :math:`~q_{ice~only} < q_{isat}` and :math:`C_{mixed~phase} = 0`

#. | :math:`~q_{cf} < 0`

where :math:`q_{cfmin}` equals :math:`1 \times 10^{-8}`
kg kg\ :math:`^{-1}`. Condition 3 is equivalent to there being no
depositional growth. Condition 4 may apply because of numerical
inaccuracies elsewhere in the scheme or model.

The second check is on snowfall that occurs at :math:`T >` 0 C. Because
of the long timesteps involved, it is possible for ice to fall a
considerable distance before seeing the melting term. Accordingly, we
apply an additional melting term, refered to as “emergency melting” in
the source code. This converts the flux :math:`S` out of a layer to an
equivalent value of :math:`q_{cf}` in the same layer and melts it to
rain (limited by the amount by which :math:`T` exceeds :math:`T_w`).
This term therefore provides a ‘bypass’ to the melting rate term
earlier. This is undesirable when precise location of the melting layer
at the surface is critical, as in an operational mesoscale forecast
environment. Hence an iterative melting option is available, which will
iterate only the melting and advection terms, and only when the timestep
to layer depth ratio gets large.

Iteration of microphysics
-------------------------

When running with long model timesteps, a substepping procedure can be
used, which steps over each model column multiple times with a shortened
timestep. The user is able to select either the number of iterations per
timestep or the desired length of each substep.

Iterations can also be used in the melting of precipitation. This is
used in models where diagnostic rain is used but accurate rain-snow
boundaries are still required for forecasting purposes. In this case,
several iterations of the melting processes PSMLT, PIMLT and PGMLT are
used to give more realistic estimates of where rain will fall and where
it will fall as snow.

Precision of variables
----------------------

To facilitate computational efficiency, the scheme has been engineered
to have controllable precision. Due to limitations on the Fortran
features that may be used, this is a compile-time rather than a run-time
setting available through the preprocessing tab in the fcm-make task.
The currently available settings are for double (64-bit) and single
(32-bit) precision as these are well supported by available hardware. In
principle, the model can be further modified for any other desired
precision.

Scientifically, proof-of-concept testing shows that there is little
impact on model evolution when reducing the precision for this scheme.
However, this testing is not exhaustive so users are advised to validate
its use for their own applications. The only scientific side-effect of
using reduced precision is to force the scheme to use a refactored
version of the saturation vapour pressure (or mixing ratio), the ‘qsat’
family of routines. These new routines are scientifically identical to
the previous versions, but facilitate controllable precision computation
and also fix a minor scientific inconsistency.

In terms of performance, the use of single precision significantly
reduces the cost of the scheme. In principle, a 50% saving is to be
hoped for, but actual gains will depend on the model configuration and
hardware used. The reduced memory requirements at single precision will
alter (usually increase) the optimum segment size, and should be
considered when tuning the model for a particular application.
Preliminary tests indicate that savings on total model runtime may be of
the order 5%.

.. _`sec:seeder_feeder`:

The sub-grid orographic seeder feeder scheme
============================================

.. _introduction-1:

Introduction
------------

This section describes the enhancement of precipitation due to sub-grid
orography via the seeder feeder effect
:raw-latex:`\citep{Bergeron:1965}`. The need for such a scheme in the UM
was demonstrated in :raw-latex:`\cite{Smith:etal:2015}`. At 1.5 km
horizontal resolution, the UM performs reasonably well in terms of
orographic rain enhancement. However at lower resolutions, the UM does
not generally produce enough orographic rain. This scheme attempts to
correct this deficiency by representing the effect of the sub-grid
orography on precipitation formation. The extra cloud liquid water
mixing ratio :math:`qcl_{orog}` (units :math:`kg~kg^{-1}`, code variable
‘:math:`ql\_orog`’) which would result from additional vertical motions
produced by the sub-grid orography is estimated. This extra water
:math:`qcl_{orog}` is not actually added to the model cloud water mixing
ratio :math:`q_{cl}`. Instead it is used in an extra call to accretion
(or riming) to enhance the production of rain (or snow).

Assumptions about the shape of the sub-grid orography
-----------------------------------------------------

The sub-grid orography is assumed to take the form of a single cosine
shaped ridge :raw-latex:`\citep{Smith:etal:2016}`, which has equal
deviations above and below the model surface. This quality is desirable
because ascents and descents are equally important, having opposite
effects on the orographic water mixing ratio. The actual shape of the
orography is currently assumed to be unimportant. The peak-to-trough
height of this sinusoidal ridge :math:`H_T` is proportional to the
standard deviation of the sub-grid orography :math:`\sigma_h`

.. math:: H_T = n \sigma_h

The variable :math:`n` is a tuning parameter (model variable
:math:`nsigmasf`). The assumed surface height standard deviation is
equal to the actual surface height standard deviation :math:`\sigma_h`
if :math:`n` is set to :math:`2 \sqrt 2`.

Calculation of the blocked layer depth
--------------------------------------

The blocking calculations described in this section are based on those
used by the gravity wave drag (GWD) scheme
:raw-latex:`\cite{Vosper:2015}`. The wind speed and Brunt Vaisala
frequency :math:`U` and :math:`N` are averaged over a layer of depth
:math:`z_{av}` adjacent to the surface as described in
:raw-latex:`\cite{Vosper:etal:2009}`. These are used to calculate the
low-level Froude number :math:`F` (given by :math:`U / N H_T`), which
determines the sub-grid blocked layer depth :math:`z_b`

.. math:: z_b ~~=~~ H_T (1 - \frac{F}{F_c})

So as the Froude number :math:`F` decreases from the critical value
:math:`F_c` (model variable :math:`fcrit`) towards zero, the blocked
layer depth :math:`z_b` increases linearly from 0 to the full mountain
peak-to-trough height :math:`H_T`. For any other values of :math:`F`,
:math:`z_b` is set to zero. The variable :math:`F_c` is a tuning
parameter, for which a physically realistic value would be 1.

The effective mountain height :math:`H_{eff}` is the height of the upper
reaches of the mountain rising above the blocked layer and therefore
producing vertical streamline displacements

.. math:: H_{eff} ~~=~~ H_T ~-~ z_b

If the blocking element of the scheme is not switched on, or if the mean
low-level Brunt-Vaisala frequency :math:`N` is less than 0 (unstable),
then :math:`z_b=`\ 0 and :math:`H_{eff} = H_T`.

Calculation of the orographic water mixing ratio
------------------------------------------------

Once the effective sub-grid hill height :math:`H_{eff}` is known, the
sub-grid orographic water mixing ratio can be estimated. The amount of
adiabatic cloud water mixing ratio produced per metre of ascent (model
variable :math:`dqldz`) is the negative of the rate of change of the
saturation vapour mixing ratio :math:`q_{sat}`, as in
:raw-latex:`\cite{Albrecht:etal:1990}`

.. math:: \frac{dq_{L}}{dz} ~=~ \frac{(\epsilon +q_{sat})q_{sat} L_v}{R_d T^2} \Gamma_s  - \frac{q_{sat} P g}{(P - e_{sat}) R_d T}

where :math:`\Gamma_s` is the Saturated Adiabatic Lapse Rate
(K m\ :math:`^{-1}`) given by (from the AMS Glossary)

.. math::

   \Gamma_s  ~=~ g ~ \frac{ 1 ~+~ (L_v q)/(R_d T) }  
       { c_{pd} ~+~ (L_v^2 q \epsilon)/(R_d T^2) }

and :math:`g` is 9.8 m s\ :math:`^{-2}`, the latent heat of vaporization
:math:`L_v` is a weak function of temperature but is approximately
2.5\ :math:`\times`\ 10\ :math:`^6` J kg\ :math:`^{-1}`, the specific
heat capacity of dry air at constant pressure :math:`c_{pd}` is
1005 J kg\ :math:`^{-1}` K\ :math:`^{-1}` and the gas constant for dry
air :math:`R_d` is 287 J kg\ :math:`^{-1}` K\ :math:`^{-1}`. The ratio
of the gas constants for dry air and water vapour, :math:`\epsilon`, is
0.622.

The change in the the grid-box mean cloud liquid water mixing ratio due
to sub-grid orographic vertical motions :math:`qcl_{orog}` can be
estimated by multiplying :math:`dqldz` by the mean ascent above the
condensation level. The scheme assumes that the orographic displacements
are evanescent, typical of the moist neutral flow common within warm
sectors of depressions. The sub-grid orographic displacement therefore
decays exponentially with altitude :math:`z` above the surface at a rate
given by the horizontal wavenumber :math:`k` of the sinusoidal
variations

.. math:: D(z) = e^{-k z / n_s}

The variable :math:`n_s` (model variable :math:`nscalesf`) is a tuning
parameter which determines the wavelength assumed by the decay equation
:math:`\lambda = n_s \Delta_s`. The assumption of a single sinusoidal
ridge within each grid-box equates to setting :math:`n_s` equal to 1.
Increasing :math:`n_s` slows the vertical decay rate, potentially
increasing the amount of orographic enhancement at higher altitudes
(assuming there is sufficient moisture).

The maximum sub-grid orographic displacement at any altitude :math:`z`,
either above or below the resolved model streamline, is
:math:`D(z) H_{eff} / 2`. The sub-grid orographic displacements across a
grid-box are thus described by

.. math:: \eta_{S}(x) ~~=~~  D(z) \frac{H_{eff}}{2} cos(kx)

If the altitude of the grid-box :math:`z` exceeds the blocked layer
depth :math:`z_b`, this orographic displacement equation is used to
estimate the sub-grid orographic cloud water mixing ratio
:math:`qcl_{orog}`. If the altitude is below :math:`z_b`, the air parcel
lies within the blocked layer and is therefore not subject to sub-grid
orographic ascent or descent and :math:`qcl_{orog}` is zero.

The equations used to estimate :math:`qcl_{orog}` depend on whether the
model grid-box already contains resolved cloud water or not. A grid-box
is treated as clear (unsaturated) unless (i) the resolved cloud water
mixing ratio :math:`q_{cl}` exceeds a very small value :math:`qcfmin`
and (ii) the grid-box mean relative humidity :math:`q`/:math:`q_{sat}`
is at least 1. Note that in the sub-grid cloud scheme, which accounts
for horizontal thermodynamic variations (e.g. in temperature and
humidity), a grid-box mean relative humidity of 1 would give a cloud
fraction of 0.5, with half the grid-box being supersaturated and half
being subsaturated. For the seeder feeder scheme however, we just want
to know whether the grid-box air is saturated on average, in order to
estimate the sub-grid orographic cloud water correctly.

Clear model grid-box
~~~~~~~~~~~~~~~~~~~~

For a clear model grid-box, the amount of sub-grid orographic ascent
which would produce water is that which occurs above the condensation
level :math:`\eta_c` as indicated by the dark shaded region in Figure 1a
in :raw-latex:`\cite{Smith:etal:2016}`. The simple calculation of
:math:`\eta_c` described in :raw-latex:`\cite{Smith:etal:2016}` is valid
for the warm, moist conditions typical of the low-level warm sector flow
considered to be responsible for most orographic rain enhancement in the
UK. Within the UM, however, the scheme will have to cope with a much
wider range of atmospheric conditions and therefore a more accurate
estimate of :math:`\eta_c` is used

.. math:: \eta_c ~~=~~ \frac{(T ~-~ T_d)}{\Gamma_d - DEWLR}

This differs in two ways from Equation (1) in
:raw-latex:`\cite{Smith:etal:2016}`. Firstly the dewpoint temperature
:math:`T_d` is estimated using

.. math:: T_d ~=~ \frac{ B_1 ( ln(RH) ~+~ \frac{A_1 T}{B_1 ~+~ T} ) }{  A_1 ~-~ ln(RH) ~-~ \frac{A_1 T}{B_1 ~+~ T} }

where :math:`RH` is the fractional relative humidity (and both T and
T\ :math:`_d` are in :math:`^{\circ}C`). The coefficients are
:math:`A_1` = 17.625 and :math:`B_1` = 243.04\ :math:`^{\circ}`\ C as
recommended by :raw-latex:`\cite{Alduchov:Eskridge:1996}`. Secondly,
instead of assuming a constant dewpoint lapse rate of 1.8 K
km\ :math:`^{-1}` (typical of the BL), the actual value :math:`DEWLR` is
derived from the Clausius-Clapeyron equation
:raw-latex:`\citep{McIlveen:2010}`

.. math:: DEWLR ~=~ \frac{T_d^2 g R_v}{L_v R_d T}

The rest of the calculations are only performed if the maximum sub-grid
orographic ascent rises above :math:`\eta_c`, giving a non-zero value
for the maximum saturated ascent :math:`\eta_{sat}` (given by
:math:`D H_{amp} - \eta_c`).

The value of :math:`dqldz` tends to decrease in a rising air parcel. So
a value estimated when the parcel has ascended to the mid-cloud level
would be more representative than a value at the model level. At this
altitude, the temperature of an adiabatically ascending parcel will have
reduced to

.. math:: T_{mc} ~=~  T ~-~ (\eta_c ~ \Gamma_d)  ~-~ (0.5 \eta_{sat} \Gamma_s)

where :math:`\eta_c` and :math:`\eta_{sat}` are the unsaturated and
saturated ascents due to the sub-grid orography and :math:`\Gamma_d` and
:math:`\Gamma_s` are the dry and saturated adiabatic lapse rates. The
value of :math:`\Gamma_d` is constant but :math:`\Gamma_s` varies with
altitude, so the value of :math:`\Gamma_s` at cloud base is used. The
pressure at the mid-cloud level is estimated using the total ascent to
mid-cloud level :math:`\eta_{mc}` (:math:`\eta_c~+~ 0.5 \eta_{sat}`)

.. math:: P_{mc} ~=~ P~ e^{ -( \eta_{mc} ~g / R_d T_v ) }

where :math:`T_v` is the mean virtual temperature of the air parcel
during its ascent from the model level up to the mid-cloud level. These
mid-cloud values :math:`T_{mc}` and P\ :math:`_{mc}` are used to
estimate :math:`dql/dz`, which is then used in the calculation of the
mean sub-grid orographic water mixing

.. math::

   qcl_{orog} ~~=~~   \frac{dq_{L}}{dz}~ \frac{1}{\Delta}~ \left ( 
   \frac{D H_{eff} ~\sin(k x_c)}{k}  ~-~  2 x_c \eta_c 
    \right )

where the horizontal cloud boundary :math:`x_c` is

.. math:: x_c ~=~ \frac{1}{k} \cos^{-1} \left ( \frac{2 \eta_c}{ D H_{eff}} \right )

The horizontal cloud boundary :math:`x_c` is used to give an estimate of
the orographic cloud fraction, required by the accretion and riming
subroutines, which will always be :math:`\le`\ 0.5 for a clear grid-box.

.. math:: cf\_orog ~=~ \frac{2 ~ x_c}{\Delta}

Cloudy model grid-box
~~~~~~~~~~~~~~~~~~~~~

This section describes how the sub-grid orographic cloud water mixing
ratio :math:`qcl_{orog}` is estimated for a model grid-box which already
contains cloud. The equations used to to estimate :math:`qcl_{orog}` in
:raw-latex:`\cite{Smith:etal:2016}` were used here. In this case
:math:`\eta_c` is the distance of the condensation level below the model
level and is calculated by estimating the descent required to evaporate
all of the resolved water :math:`q_{cl}`

.. math:: \eta_c  ~~=~~  \frac{q_{cl}}{ dq_{L}/dz }

The sub-grid orographic vertical motions occurring above the saturation
level :math:`\eta_c` are integrated across the sub-grid ridge, with the
descents partially offsetting the ascents as indicated by Figure 1b of
:raw-latex:`\cite{Smith:etal:2016}`. This integrated saturated ascent is
divided by the grid-spacing :math:`\Delta` to give a mean saturated
orographic ascent. The value of :math:`dqldz` is calculated using the
grid-box variables and multiplying this by the mean ascent gives

.. math::

   qcl_{orog} ~~=~~   \frac{dq_{L}}{dz}~ \frac{1}{\Delta}~  \left (  
     \frac{ D H_{eff} sin(k x_c) }{k}  ~-~ 2 (\frac{\Delta}{2} ~-~ x_c ) \eta_c
    \right )

where the horizontal cloud boundary, :math:`x_c`, is given by

.. math:: x_c ~=~ \frac{1}{k} cos^{-1} \left ( \frac{2 \eta_c}{ D H_{eff} } \right )

This cloud boundary is used to estimate an orographic cloud fraction

.. math:: cf\_orog ~=~ \frac{2 ~ x_c}{\Delta}

assuming that the grid-box is completely cloudy (:math:`cfliq=1`) and
that the pre-existing cloud is horizontally homogeneous within the
grid-box. This will always be :math:`\ge` 0.5 for a grid-box containing
resolved cloud.

How the sub-grid orographic water is used to enhance precipitation
------------------------------------------------------------------

The sub-grid orographic water mixing ratio :math:`qcl_{orog}` calculated
as described in the previous section is not added to the resolved cloud
water mixing ratio :math:`q_{cl}`. Instead it is used only to produce
extra rain and snow *via* accretion and riming. In this section the
model variable names are used to describe the calculations.

Accretion removes mass from the cloud water mixing ratio :math:`qcl` and
transfers it to the rain mixing ratio :math:`qrain`. So in order to be
able to take the extra accreted water mass directly from the vapour
field :math:`q`, accretion is called twice: first for the resolved water
:math:`qcl` and then for the sub-grid orographic cloud water
:math:`ql\_orog` (:math:`qcl_{orog}`). To enable the resolved and
orographic accretion to be applied in parallel using the same rain
mixing ratio, :math:`qrain` (model variable for :math:`q_R`) is saved
into temporary variables :math:`qrain1a` and :math:`qrain1b` before the
first accretion call (and similarly the transfer rate :math:`pracw` (the
model variable for :math:`P_{RACW}`) is saved into :math:`pracw1a` and
:math:`pracw1b`). The temporary variables :math:`qrain1b` and
:math:`pracw1b` are used in the orographic accretion call, while
:math:`qrain1a` and :math:`pracw1a` save the original values. The extra
rain due to the sub-grid orography is thus
:math:`dqrain = qrain1b - qrain1a`, which is added to the rain field
:math:`qrain` (output from the resolved accretion call) and subtracted
from the vapour field :math:`q`. The extra mass transfer is added to the
transfer rate :math:`pracw` output from the resolved water call. The
temperature :math:`T` is corrected for the extra latent heating due to
the condensation of the orographic water that is actually accreted. This
temperature change is given by :math:`dT = dqrain * lcrcp`, where
:math:`lcrcp = L_v/c_{pm}` and :math:`L_v` is the latent heat of
condensation and :math:`c_{pm}` is the specific heat capacity of moist
air at constant pressure.

Riming enhancement is carried out in much the same way as the accretion
enhancement. The main difference is that the riming subroutine modifies
the temperature field :math:`T` to account for the latent heat due to
freezing of the rimed water. So the changes to :math:`T` are also dealt
with in the orographic call using temporary variables (:math:`t1a` and
:math:`t1b`). Subsequently, the extra latent heating due to the
condensation and then freezing of the orographic water that is actually
rimed, :math:`dqsnow * lsrcp`, is added to :math:`T`. Here,
:math:`lsrcp = L_s/c_{pm}` where :math:`L_s` is the latent heat of
sublimation.

Overlap of orographic water with rain and snow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The overlaps of the orographic cloud water with rain or snow are
estimated using the same assumptions as for the resolved cloud water.
Again the model variable names are used to describe these equations.

The overlap of the sub-grid orographic cloud with rain is given the
maximum possible value:

.. math:: rain\_liq\_orog = MAX(  MIN(cf\_orog, rainfrac),  0 )

where :math:`rainfrac` is the fraction of the gridbox containing rain.
The variable :math:`rain\_mix\_orog` (where ice is also present) is set
to zero because only the sum of these two overlap parameters is actually
used by the accretion scheme.

The overlap of the sub-grid orographic cloud with snow is given the
minimum possible value needed to prevent the total cloud and snow cover
from exceeding 1:

.. math:: area\_mix\_orog =  MAX( (cf\_orog + cfice - 1) ,0 )

where :math:`cfice` is the fractional grid-box coverage of the resolved
ice and snow. Then the fractional coverage of liquid where there is no
snow is

.. math:: area\_liq\_orog = MAX( (cf\_orog - area\_mix\_orog), 0  )

Appendix I: Relationship between rain rate, particle size distribution and fall velocity (with thanks to Cyril Morcrette)
-------------------------------------------------------------------------------------------------------------------------

The rainrate in the UM is defined as the product of the number of drops,
:math:`n(D)~dD`, their mass, :math:`m(D)` and fall velocity,
:math:`v(D)` integrated over the drop size distribution (DSD) spectrum.

.. math::

   R=\int_{0}^{\infty} n(D) m(D) v(D) dD 
   \label{eqn:define_r}

Let us look at each of the elements which make up the right hand side in
turn. In the Unified Model (UM) large-scale precipitation scheme the
number of raindrops of a given size, :math:`n(D)`, i.e. the DSD is
assumed to be of the form

.. math::

   n(D)=x_{1R} \lambda^{x_{2R}} D^{x_{4R}} exp(- \lambda D)
   \label{eqn:general_gamma_dsd}

where :math:`\lambda`, which depends on the rainrate, represents the
slope of the distribution, :math:`D` is the diameter of the raindrop and
the subscript :math:`R` in :math:`x_{1R}`, :math:`x_{2R}` and
:math:`x_{4R}` indicates that these DSD parameters are valid for rain.
For simplicity we will no longer use the :math:`R` subscripts, but we
must remember that a different set of values for :math:`x_{1}`,
:math:`x_{2}` and :math:`x_{4}` are used for aggregates and for ice
crystals. The form of the DSD given by eqn.
`[eqn:general_gamma_dsd] <#eqn:general_gamma_dsd>`__ is a general gamma
distribution. The value of :math:`x_{4}` currently in the model is zero,
so the DSD actually simplifies to a modified exponential distribution.
However for completeness, the parameter :math:`x_{4}` is retained in the
derivations that follow. The mass of a raindrop is given by the product
of its volume and density:

.. math::

   \begin{aligned}
   m(D)&=&\frac{4}{3}\pi r^{3} \rho_{w}\nonumber \\
   &=&\frac{\pi}{6} D^{3} \rho_{w}
   \end{aligned}

where :math:`\rho_{w}` is the density of liquid water and the radius,
:math:`r`, of a drop is half its diameter. Finally the fall velocity of
the raindrops is assumed to be related to the diameter according to a
power law with a density correction to take account of drops falling
slower in denser air.

.. math:: v(D)=c_{R} D^{d_{R}}\Big(\frac{\rho_{0}}{\rho}\Big)^{g_{R}}

At low altitudes, where :math:`\rho \simeq \rho_{0}` the density
correction is small and can be neglected for simplicity. Substituting
for :math:`n(D)`, :math:`m(D)` and :math:`v(D)` in eqn.
`[eqn:define_r] <#eqn:define_r>`__ gives

.. math::

   \begin{aligned}
   R&=&\int_{0}^{\infty} x_{1} \lambda^{x_{2}} D^{x_{4}} exp(- \lambda D) \frac{\pi}{6} D^{3} \rho_{w} c_{R} D^{d_{R}} \ dD \nonumber \\ 
   &=& x_{1} \lambda^{x_{2}} \frac{\pi}{6} \rho_{w} c_{R} \int_{0}^{\infty}  D^{x_{4}} exp(- \lambda D) D^{3} D^{d_{R}} \ dD \nonumber \\
   &=& x_{1} \lambda^{x_{2}} \frac{\pi}{6} \rho_{w} c_{R} \int_{0}^{\infty}  D^{(x_{4}+3+d_{R})} exp(- \lambda D) \ dD
   \end{aligned}

We make use of the gamma function defined (for example by
:raw-latex:`\cite{dz84}`) as

.. math:: \frac{1}{\mu^{\nu}}\Gamma(\nu)=\int_{0}^{\infty} x^{\nu-1} exp(-\mu x) dx

to write

.. math::

   \begin{aligned}
   R&=&x_{1} \lambda^{x_{2}} \frac{\pi}{6} \rho_{w} c_{R} 
   \frac{\Gamma(x_{4}+3+d_{R}+1)}{\lambda^{(x_{4}+3+d_{R}+1)}} \nonumber \\
   &=&x_{1} \frac{\pi}{6} \rho_{w} c_{R} \frac{\Gamma(x_{4}+4+d_{R})}{\lambda^{(x_{4}+4+d_{R}-x_{2})}}
   \end{aligned}

which can be re-arranged to give

.. math::

   \lambda=\Big ( \frac{x_{1} \pi \rho_{w} c_{R} \Gamma(x_{4}+4+d_{R})}{6 R} \Big )^{\frac{1}{(x_{4}+4+d_{R}-x_{2})}}
   \label{eqn:lambda}

Appendix II: Interface with UKCA
--------------------------------

The UKCA chemistry and aerosols sub-model takes a number of large scale
cloud and precipitation diagnostics as input. For a list of these and a
brief explanation of how they are used see the table below. If any
changes modify the results for these variables it will prevent UKCA jobs
from regressing. If the changes are significant it would be prudent to
discuss them with the UKCA code owner before lodging the change.

.. container:: center

   .. container::
      :name: tab:ukca

      .. table:: Precipitation Diagnostics which are used by UKCA

         +-------------------+------+-------------------+-------------------+
         | Precipitation     |      |                   |                   |
         | inputs to UKCA    |      |                   |                   |
         +===================+======+===================+===================+
         | Sec               | Item | Description       | Use in UKCA       |
         +-------------------+------+-------------------+-------------------+
         | 4                 | 205  | CLOUD LIQUID      | Used in activate  |
         |                   |      | WATER AFTER LS    | and aerosol_ctl   |
         |                   |      | PRECIP            |                   |
         +-------------------+------+-------------------+-------------------+
         | 4                 | 222  | RAINFALL RATE OUT | Used in chemistry |
         |                   |      | OF MODEL LEVELS   | and aerosols      |
         +-------------------+------+-------------------+-------------------+
         | 4                 | 223  | SNOWFALL RATE OUT | Used in chemistry |
         |                   |      | OF MODEL LEVELS   | and aerosols      |
         +-------------------+------+-------------------+-------------------+

Appendix III: Calculation of Radar Reflectivity
-----------------------------------------------

Radar Reflectivity is used as an alternative or in addition to
precipitation rate to determining precipitation strength. Use of radar
reflectivity rather than rain rate is common in the USA. Radar
reflectivity diagnostics are also of interest to those examining radar
data directly and also for data assimilation.

It is possible to calculate radar reflectivity from the microphysics
code. This is done with the following assumptions:

- **Rayleigh Scattering** is assumed, which is valid for most rain
  radars, but is not valid for cloud radars (which typically operate at
  frequencies greater than 20 GHz).

- **The bright band** is not explicitly modelled.

- **Attenuation** is not accounted for and the calculation makes no
  assumption on the location of the radar.

Diagnostics currently available are shown in table `17 <#tab:radar>`__.
It is anticipated that the 2D diagnostics will be used operationally and
could be archived, while the 3D diagnostics may be of use for research
purposes and for data assimilation.

.. container:: center

   .. container::
      :name: tab:radar

      .. table:: Available radar reflectivity diagnostics (all
      diagnostics are contained in section 4).

         +------+--------------------------+------+--------------------------+
         | Item | Description              | Dim. | Notes                    |
         +======+==========================+======+==========================+
         | 110  | Surface Radar            | 2D   | Uses model level 1 from  |
         |      | Reflectivity (dBZ)       |      | item 118                 |
         +------+--------------------------+------+--------------------------+
         | 111  | Max Reflectivity in      | 2D   | Determined for each      |
         |      | Column (dBZ)             |      | column                   |
         +------+--------------------------+------+--------------------------+
         |      |                          |      | from item 118            |
         +------+--------------------------+------+--------------------------+
         | 112  | Radar Reflectivity at    | 2D   | Determined from item 118 |
         |      | 1km AGL (dBZ)            |      |                          |
         +------+--------------------------+------+--------------------------+
         | 113  | Graupel Radar            | 3D   |                          |
         |      | Reflectivity (dBZ)       |      |                          |
         +------+--------------------------+------+--------------------------+
         | 114  | Ice Aggregate Radar      | 3D   |                          |
         |      | Reflectivity (dBZ)       |      |                          |
         +------+--------------------------+------+--------------------------+
         | 115  | Ice Crystal Radar        | 3D   |                          |
         |      | Reflectivity (dBZ)       |      |                          |
         +------+--------------------------+------+--------------------------+
         | 116  | Rain Radar Reflectivity  | 3D   |                          |
         |      | (dBZ)                    |      |                          |
         +------+--------------------------+------+--------------------------+
         | 117  | Liquid Cloud Radar       | 3D   |                          |
         |      | Reflectivity (dBZ)       |      |                          |
         +------+--------------------------+------+--------------------------+
         | 118  | Total Radar Reflectivity | 3D   | Linear sum of items 113  |
         |      | (dBZ)                    |      | to 117                   |
         +------+--------------------------+------+--------------------------+

The diagnostics are calculated in the same manner as Appendix A of
:raw-latex:`\cite{Stein:etal:2014}`, which is based upon the Appendix of
:raw-latex:`\cite{McBeath:etal:2014}`, which is itself based upon
:raw-latex:`\cite{Gaussiat:2008}`. As Rayleigh scattering is assumed,
reflectivity is considered proportional to mass squared. The linear
radar reflectivity for ice crystals, ice aggregates, rain and graupel is
given as

.. math::

   \label{eq:z_lin}
   Z_{lin_x} = \hat{Q_x} \int_0^{\infty} |M_x(D)|^2 n_x(D) dD,

with :math:`n_x(D)` being determined by equation
`[eq:mic_nx] <#eq:mic_nx>`__ and :math:`M_x(D)` being determined by
equation `[eq:m_x] <#eq:m_x>`__. :raw-latex:`\cite{Stein:etal:2014}`
show that by including equations `[eq:mic_nx] <#eq:mic_nx>`__ and
`[eq:m_x] <#eq:m_x>`__ into equation `[eq:z_lin] <#eq:z_lin>`__ and
using the value of :math:`\lambda_x` determined in section
`4.6 <#mr2psd>`__ then

.. math::

   \label{eq:z_lin2}
   Z_{lin_x} = \hat{Q_x}~ C_x~n_{ax}~(a_x)^2~ \Gamma(1+2b_x+\alpha_x)~ \lambda_x^{-(1+2b_x+\alpha_x-n_{bx})},

with, :math:`C_x` being the cloud fraction of that grid box and
:math:`\lambda` being calculated for the in-cloud water content, rather
than the grid box mean. This is used for all species with two
exceptions:

| **1. With the generic ice particle size distribution**
| When the generic ice particle option is switched on, equation
  `[eq:z_lin2] <#eq:z_lin2>`__ is modified for the aggregates category
  as

  .. math::

     \label{eq:z_psd}
     Z_{lin_a} = 0.224 \times 10^{18} \left(\frac{6 ai/\pi}{\rho_a}\right)^2 \mathcal{M}_4,

  where in this case, :math:`\mathcal{M}_4` is equivalent to
  :math:`2.0 \times b_i`.

| **2. Liquid Cloud**
| This follows :raw-latex:`\cite{Stein:etal:2014}` and
  :raw-latex:`\cite{McBeath:etal:2014}`, who derive a relationship of
  the form

  .. math::

     \label{eq:z_liq}
     Z_{lin_{cl}} = \hat{Q_{cl}} \frac{5.6}{n_d} LWC^2,

  where LWC is the in-cloud liquid water content and :math:`n_d` is the
  cloud drop number concentration, as determined in section
  `6.2 <#sec:cloud_drop_calc>`__. Thus, the radar reflectivity due to
  liquid cloud will change in response to cloud drop number changes
  (e.g. by movement of different aerosol masses).

Finally, the value :math:`\hat{Q_x}` is taken as

.. math::

   \label{eq:qhat}
   \hat{Q_x} = 10^{18} \frac{|K_x|^2}{0.93}\left(\frac{6}{\pi \rho_x}\right)^2,

with the only two unknowns now being :math:`|K_x|^2` and :math:`\rho_x`.

.. container:: center

   .. container::
      :name: tab:rad_param

      .. table:: Constants used in the Radar Reflectivity Calculations.

         +----------------+----------------+----------------+----------------+
         | Category       | :              | :math:`\rho_x` | Notes          |
         |                | math:`|K_x|^2` | [kg            |                |
         |                |                | m\             |                |
         |                |                | :math:`^{-3}`] |                |
         +================+================+================+================+
         | Liquid Cloud,  | 0.93           | 1000           |                |
         | Rain           |                |                |                |
         +----------------+----------------+----------------+----------------+
         | Ice            | 0.174          | 900            |                |
         | Aggregates,    |                |                |                |
         | Ice Crystals   |                |                |                |
         +----------------+----------------+----------------+----------------+
         | Graupel        | 0.174          | 500            | See Section    |
         |                |                |                | `4.5 <#s       |
         |                |                |                | ec:density>`__ |
         +----------------+----------------+----------------+----------------+

The factor :math:`10^{18}` in equations `[eq:z_psd] <#eq:z_psd>`__ and
`[eq:qhat] <#eq:qhat>`__ ensures that the units are
mm\ :math:`^6`\ m\ :math:`^{-3}`, but before output, this is converted
to dBZ (which is more widely used) as:

.. math::

   \label{eq:dbz}
   Z_{dbZ} = 10.0 ~ \mathrm{LOG}_{10}(Z_{lin}).

A minimum reflectivity value of -40.0 dBZ is applied throughout the
domain; this is because a linear reflectivity of zero will generate a
model error when equation `[eq:dbz] <#eq:dbz>`__ is applied and a radar
reflectivity of zero dBZ could be confused with cloud or light
precipitation.

Appendix IV: Precipitation Rate and Amount Diagnostics
------------------------------------------------------

The large-scale precipitation scheme is capable of producing a number of
different precipitation diagnostics for different requirements and some
explanation of these diagnostics is probably helpful to the user.

Originally the UM large-scale precipitation scheme ran with a single ice
prognostic. When the second ice prognostic and graupel were introduced,
these were automatically included in the snowfall rate diagnostics, so
that no frozen precipitation was omitted. However, other parts of the
model (e.g. the land surface) may wish to treat graupel differently from
snow, due to their different density and fallspeed properties.
Therefore, additional diagnostics were produced at UM vn10.7 to output
values of graupel alone, along with snowfall excluding graupel, yet
while still preserving the original precipitation rate and amount
diagnostics unchanged.

Table `19 <#tab:precip_diag>`__ describes the precipitation diagnostics
available and details which hydrometeor species are used to produce
those diagnostics. The following guidance points should be noted:

- All precipitation rate diagnostics are contained in STASH section 4.

- All 2D diagnostics in table `19 <#tab:precip_diag>`__ are at the
  surface (i.e. precipitation out of the lowest model level).

- The effects of any gravitational droplet settling (see section
  `6.3.1 <#sec:PLSET>`__) are included in the rainfall diagnostics.

- The effects of ice crystals are included in the diagnostics whenever
  the Generic Ice Particle Size Distribution (see section
  `4.3 <#sec:field_psd>`__) is not included.

- All ‘amount’ diagnostics are the precipitation amount generated over
  the model timestep. These are generally output as STASH accumulations,
  to give accumulated precipitation over a specified time period (e.g. 1
  hour; 6 hours; 1 day).

- All ‘rate’ diagnostics are in units of kg
  m\ :math:`^{-2}`\ s\ :math:`^{-1}`, equivalent to mm s\ :math:`^{-1}`.
  In any analysis after the model run, these can be multiplied by 3600
  or 86400 to obtain rainfall/snowfall in mm hour\ :math:`^{-1}` and mm
  day\ :math:`^{-1}` respectively.

- In any analysis post-model run, **do not** add graupel rate or amount
  diagnostics to snowfall rate and amount diagnostics which already
  include graupel as this will make any results obtained incorrect.

.. container:: center

   .. container::
      :name: tab:precip_diag

      .. table:: Precipitation Rate and Amount Diagnostics currently
      available from the large-scale precipitation scheme. In the units
      column, ‘ts’ denotes the model timestep.

         +------+-----------------+-------+-----------------+-----------------+
         | Item | Description     | 2D/3D | Hydrometeor     | Units           |
         |      |                 |       | Species         |                 |
         +======+=================+=======+=================+=================+
         | 201  | Large Scale     | 2D    | Rain;           | kg              |
         |      | Rain Amount     |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | ts              |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Liquid Cloud    |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 202  | Large Scale     | 2D    | Ice Aggregates; | kg              |
         |      | Snow Amount     |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | ts              |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Ice Crystals;   |                 |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Graupel         |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 203  | Large Scale     | 2D    | Rain;           | kg              |
         |      | Rain Rate       |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Liquid Cloud    |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 204  | Large Scale     | 2D    | Ice Aggregates; | kg              |
         |      | Snow Rate       |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Ice Crystals;   |                 |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Graupel         |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 209  | Large Scale     | 2D    | Graupel         | kg              |
         |      | Graupel         |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | ts              |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      | Amount          |       |                 |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 212  | Large Scale     | 2D    | Graupel         | kg              |
         |      | Graupel         |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      | Rate            |       |                 |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 222  | Rain Rate on    | 3D    | Rain;           | kg              |
         |      | Model Levels    |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Liquid Cloud    |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 223  | Snow Rate on    | 3D    | Ice Aggregates; | kg              |
         |      | Model Levels    |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Ice Crystals;   |                 |
         +------+-----------------+-------+-----------------+-----------------+
         |      |                 |       | Graupel         |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 226  | Graupel Rate on | 3D    | Graupel         | kg              |
         |      | Model levels    |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         | 302  | Large Scale     | 2D    | Ice Aggregates; | kg              |
         |      | Snow Amount     |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | ts              |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      | excluding       |       | Ice Crystals    |                 |
         |      | graupel         |       |                 |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 304  | Large Scale     | 2D    | Ice Aggregates; | kg              |
         |      | Snow Rate       |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+
         |      | excluding       |       | Ice Crystals    |                 |
         |      | graupel         |       |                 |                 |
         +------+-----------------+-------+-----------------+-----------------+
         | 323  | Snow Rate on    | 3D    | Ice Aggregates; |                 |
         |      | Model Levels    |       |                 |                 |
         +------+-----------------+-------+-----------------+-----------------+
         |      | excluding       |       | Ice Crystals    | kg              |
         |      | graupel         |       |                 | m               |
         |      |                 |       |                 | \ :math:`^{-2}` |
         |      |                 |       |                 | s               |
         |      |                 |       |                 | \ :math:`^{-1}` |
         +------+-----------------+-------+-----------------+-----------------+

Appendix V: Maximum Hail Size Diagnostics
-----------------------------------------

This set of diagnostics calculates the maximum expected hail size using
information from the graupel scheme in the microphysics. It was
originally developed by Gregory Thompson at NCAR for the purpose of
comparing the output from different microphysics schemes in the WRF
model and for actually forecasting potential maximum hail size and has
now been adapted for use in the UM.

The methodology sets up number of hail size bins (currently 50) which
vary in size from 0.5 to 75 mm, with a variable and non-linear bin
width. The method performs an integration of the number concentration in
each bin, starting with the largest and proceeding towards the smallest.
The maximum hail size is determined as the centre of the bin in which
the value of the integration exceeds a threshold number concentration of
0.005 m\ :math:`^{-3}`. Should the graupel water content be less than
:math:`10^{-10}` kg m\ :math:`^{-3}`, then the maximum hail size
returned is zero.

Within the UM single-moment microphysics, this will purely be a function
of the graupel water content (i.e. mass mixing ratio multiplied by air
density). Therefore, a look-up table has been generated which calculates
the minimum ice water content required for each of the hail size bins.
This uses particle size distribution information from table
`2 <#tab:mic_consts_psd>`__. The look-up table is automatically
generated the first time any of the maximum hail size diagnostics are
requested and the information is then saved for the remainder of the
model run. Should the constants in table `2 <#tab:mic_consts_psd>`__ be
altered (i.e. through a code change), the values in the look-up table
will change based on the new particle size distribution information.

The diagnostics that are available are all in section 4 and are all
output in common units of mm to be easier to pack operationally. It
should be noted that item 275 is often entirely zero, unless there is a
significant amount of graupel in the model simulation or the freezing
level is close to the surface.

.. container:: center

   .. container::
      :name: tab:max_hail_size

      .. table:: Maximum hail size diagnostics available from section 4
      of the microphysics scheme.

         ==== ======================================== =====
         Item Description                              2D/3D
         ==== ======================================== =====
         275  Surface maximum predicted hail size [mm] 2D
         276  Maximum hail size in model column [mm]   2D
         277  Maximum hail size on model levels [mm]   3D
         ==== ======================================== =====

.. [1]
   This should not be confused with the exponent of the fallspeed air
   density correction used from equation `[eq:mic_vxd] <#eq:mic_vxd>`__
   onwards. To avoid any confusion, in this document ‘:math:`g`’ will be
   used for acceleration due to gravity and ‘:math:`\mathcal{G}`’ in the
   fall speed correction with air density.

.. [2]
   when crystals are used, aggregates and crystals are classed together
   as ice, graupel is ignored at present

.. [3]
   This is defined as :math:`a/b` in :raw-latex:`\cite{Rogers:Yau:1989}`
   and :raw-latex:`\cite{pruppacher:klett}`. In their notation,
   :math:`a` is the major semi-axes while :math:`b` is the minor
   semi-axes.

.. [4]
   This should not be confused with the radar bright-band, which would
   not normally be present in model data is and regularly filtered out
   of radar observations

.. [5]
   In practice, the rain fall-flux does eventually get forced to zero
   but only because the sedimentation code removes fluxes below a tiny
   numerical tolerance for computational efficiency.

.. |image1| image:: tnuc_new
