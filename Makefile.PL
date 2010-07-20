use inc::Module::Install;

name            ("MooseX-Types-Timestamp");
abstract        ("Timestamp subtypes for Moose classes");
author          ("Sam Vilain <samv@cpan.org>");
version_from    ("lib/MooseX/Types/Timestamp.pm");
license         ("perl");

requires        ("perl" => 5.006);
requires        ("Memoize");
requires        ("Moose" => 0.32);
requires        ("Sub::Exporter");

&WriteAll;
