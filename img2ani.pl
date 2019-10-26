#!/usr/bin/perl
use strict;
use warnings;
use autodie;
use utf8;
use Carp qw(croak);
use Cwd;
use DateTime;
use feature qw(say);
use File::Basename qw(basename);
use constant ARRAY => ref [];
use constant HASH  => ref {};
BEGIN { unshift @INC, "./lib"; } # @INC's become dotless since v5.26000
use My::Moose::Animate;


our $VERSION = '1.01';
our $LAST    = '2019-10-26';
our $FIRST   = '2019-04-28';


#----------------------------------My::Toolset----------------------------------
sub show_front_matter {
    # """Display the front matter."""

    my $prog_info_href = shift;
    my $sub_name = join('::', (caller(0))[0, 3]);
    croak "The 1st arg of [$sub_name] must be a hash ref!"
        unless ref $prog_info_href eq HASH;

    # Subroutine optional arguments
    my(
        $is_prog,
        $is_auth,
        $is_usage,
        $is_timestamp,
        $is_no_trailing_blkline,
        $is_no_newline,
        $is_copy,
    );
    my $lead_symb = '';
    foreach (@_) {
        $is_prog                = 1  if /prog/i;
        $is_auth                = 1  if /auth/i;
        $is_usage               = 1  if /usage/i;
        $is_timestamp           = 1  if /timestamp/i;
        $is_no_trailing_blkline = 1  if /no_trailing_blkline/i;
        $is_no_newline          = 1  if /no_newline/i;
        $is_copy                = 1  if /copy/i;
        # A single non-alphanumeric character
        $lead_symb              = $_ if /^[^a-zA-Z0-9]$/;
    }
    my $newline = $is_no_newline ? "" : "\n";

    #
    # Fill in the front matter array.
    #
    my @fm;
    my $k = 0;
    my $border_len = $lead_symb ? 69 : 70;
    my %borders = (
        '+' => $lead_symb.('+' x $border_len).$newline,
        '*' => $lead_symb.('*' x $border_len).$newline,
    );

    # Top rule
    if ($is_prog or $is_auth) {
        $fm[$k++] = $borders{'+'};
    }

    # Program info, except the usage
    if ($is_prog) {
        $fm[$k++] = sprintf(
            "%s%s - %s%s",
            ($lead_symb ? $lead_symb.' ' : $lead_symb),
            $prog_info_href->{titl},
            $prog_info_href->{expl},
            $newline,
        );
        $fm[$k++] = sprintf(
            "%s%s v%s (%s)%s",
            ($lead_symb ? $lead_symb.' ' : $lead_symb),
            $prog_info_href->{titl},
            $prog_info_href->{vers},
            $prog_info_href->{date_last},
            $newline,
        );
        $fm[$k++] = sprintf(
            "%sPerl %s%s",
            ($lead_symb ? $lead_symb.' ' : $lead_symb),
            $^V,
            $newline,
        );
    }

    # Timestamp
    if ($is_timestamp) {
        my %datetimes = construct_timestamps('-');
        $fm[$k++] = sprintf(
            "%sCurrent time: %s%s",
            ($lead_symb ? $lead_symb.' ' : $lead_symb),
            $datetimes{ymdhms},
            $newline,
        );
    }

    # Author info
    if ($is_auth) {
        $fm[$k++] = $lead_symb.$newline if $is_prog;
        $fm[$k++] = sprintf(
            "%s%s%s",
            ($lead_symb ? $lead_symb.' ' : $lead_symb),
            $prog_info_href->{auth}{$_},
            $newline,
        ) for (
            'name',
#            'posi',
#            'affi',
            'mail',
        );
    }

    # Bottom rule
    if ($is_prog or $is_auth) {
        $fm[$k++] = $borders{'+'};
    }

    # Program usage: Leading symbols are not used.
    if ($is_usage) {
        $fm[$k++] = $newline if $is_prog or $is_auth;
        $fm[$k++] = $prog_info_href->{usage};
    }

    # Feed a blank line at the end of the front matter.
    if (not $is_no_trailing_blkline) {
        $fm[$k++] = $newline;
    }

    #
    # Print the front matter.
    #
    if ($is_copy) {
        return @fm;
    }
    else {
        print for @fm;
        return;
    }
}


sub validate_argv {
    # """Validate @ARGV against %cmd_opts."""

    my $argv_aref     = shift;
    my $cmd_opts_href = shift;
    my $sub_name = join('::', (caller(0))[0, 3]);
    croak "The 1st arg of [$sub_name] must be an array ref!"
        unless ref $argv_aref eq ARRAY;
    croak "The 2nd arg of [$sub_name] must be a hash ref!"
        unless ref $cmd_opts_href eq HASH;

    # For yn prompts
    my $the_prog = (caller(0))[1];
    my $yn;
    my $yn_msg = "    | Want to see the usage of $the_prog? [y/n]> ";

    #
    # Terminate the program if the number of required arguments passed
    # is not sufficient.
    #
    my $argv_req_num = shift; # (OPTIONAL) Number of required args
    if (defined $argv_req_num) {
        my $argv_req_num_passed = grep $_ !~ /-/, @$argv_aref;
        if ($argv_req_num_passed < $argv_req_num) {
            printf(
                "\n    | You have input %s nondash args,".
                " but we need %s nondash args.\n",
                $argv_req_num_passed,
                $argv_req_num,
            );
            print $yn_msg;
            while ($yn = <STDIN>) {
                system "perldoc $the_prog" if $yn =~ /\by\b/i;
                exit if $yn =~ /\b[yn]\b/i;
                print $yn_msg;
            }
        }
    }

    #
    # Count the number of correctly passed command-line options.
    #

    # Non-fnames
    my $num_corr_cmd_opts = 0;
    foreach my $arg (@$argv_aref) {
        foreach my $v (values %$cmd_opts_href) {
            if ($arg =~ /$v/i) {
                $num_corr_cmd_opts++;
                next;
            }
        }
    }

    # Fname-likes
    my $num_corr_fnames = 0;
    $num_corr_fnames = grep $_ !~ /^-/, @$argv_aref;
    $num_corr_cmd_opts += $num_corr_fnames;

    # Warn if "no" correct command-line options have been passed.
    if (not $num_corr_cmd_opts) {
        print "\n    | None of the command-line options was correct.\n";
        print $yn_msg;
        while ($yn = <STDIN>) {
            system "perldoc $the_prog" if $yn =~ /\by\b/i;
            exit if $yn =~ /\b[yn]\b/i;
            print $yn_msg;
        }
    }

    return;
}


sub show_elapsed_real_time {
    # """Show the elapsed real time."""

    my @opts = @_ if @_;

    # Parse optional arguments.
    my $is_return_copy = 0;
    my @del; # Garbage can
    foreach (@opts) {
        if (/copy/i) {
            $is_return_copy = 1;
            # Discard the 'copy' string to exclude it from
            # the optional strings that are to be printed.
            push @del, $_;
        }
    }
    my %dels = map { $_ => 1 } @del;
    @opts = grep !$dels{$_}, @opts;

    # Optional strings printing
    print for @opts;

    # Elapsed real time printing
    my $elapsed_real_time = sprintf("Elapsed real time: [%s s]", time - $^T);

    # Return values
    if ($is_return_copy) {
        return $elapsed_real_time;
    }
    else {
        say $elapsed_real_time;
        return;
    }
}


sub pause_shell {
    # """Pause the shell."""

    my $notif = $_[0] ? $_[0] : "Press enter to exit...";

    print $notif;
    while (<STDIN>) { last; }

    return;
}


sub construct_timestamps {
    # """Construct timestamps."""

    # Optional setting for the date component separator
    my $date_sep  = '';

    # Terminate the program if the argument passed
    # is not allowed to be a delimiter.
    my @delims = ('-', '_');
    if ($_[0]) {
        $date_sep = $_[0];
        my $is_correct_delim = grep $date_sep eq $_, @delims;
        croak "The date delimiter must be one of: [".join(', ', @delims)."]"
            unless $is_correct_delim;
    }

    # Construct and return a datetime hash.
    my $dt  = DateTime->now(time_zone => 'local');
    my $ymd = $dt->ymd($date_sep);
    my $hms = $dt->hms($date_sep ? ':' : '');
    (my $hm = $hms) =~ s/[0-9]{2}$//;

    my %datetimes = (
        none   => '', # Used for timestamp suppressing
        ymd    => $ymd,
        hms    => $hms,
        hm     => $hm,
        ymdhms => sprintf("%s%s%s", $ymd, ($date_sep ? ' ' : '_'), $hms),
        ymdhm  => sprintf("%s%s%s", $ymd, ($date_sep ? ' ' : '_'), $hm),
    );

    return %datetimes;
}


sub rm_duplicates {
    # """Remove duplicate items from an array."""

    my $aref = shift;
    my $sub_name = join('::', (caller(0))[0, 3]);
    croak "The 1st arg of [$sub_name] must be an array ref!"
        unless ref $aref eq ARRAY;

    my(%seen, @uniqued);
    @uniqued = grep !$seen{$_}++, @$aref;
    @$aref = @uniqued;

    return;
}
#-------------------------------------------------------------------------------


sub parse_argv {
    # """@ARGV parser"""

    my(
        $argv_aref,
        $cmd_opts_href,
        $run_opts_href,
    ) = @_;
    my %cmd_opts = %$cmd_opts_href; # For regexes

    # Parser: Overwrite default run options if requested by the user.
    my $field_sep = ',';
    foreach (@$argv_aref) {
        # Raster directory
        if (/$cmd_opts{img_dir}/) {
            s/$cmd_opts{img_dir}//;
            $run_opts_href->{img_dir}[0] = $_ if -d;
        }

        # Sequence basename
        if (/$cmd_opts{seq_bname}/i) {
            s/$cmd_opts{seq_bname}//i;
            if (/re[!].*[!]/i) {
                s/re[!]{1} (.*) [!]{1}/$1/ix;
                $_ = qr/$_/;
            }
            $run_opts_href->{seq_bname} = $_;
        }

        # To-be-animated raster format
        if (/$cmd_opts{img_fmt}/i) {
            ($run_opts_href->{img_fmt} = $_) =~
                s/$cmd_opts{img_fmt}//i;
        }

        # Animation file basename
        if (/$cmd_opts{ani_bname}/i) {
            ($run_opts_href->{ani_bname} = $_) =~
                s/$cmd_opts{ani_bname}//i;
        }

        # Animation formats
        if (/$cmd_opts{ani_fmts}/i) {
            s/$cmd_opts{ani_fmts}//;
            my %_anim_fmts = map { $_ => 1 } qw(
                gif
                avi
                mp4
            );
            @{$run_opts_href->{ani_fmts}} =
                grep { $_anim_fmts{$_} } split /$field_sep/;
            @{$run_opts_href->{ani_fmts}} =
                (keys %_anim_fmts) if /all/i;
        }

        # Animation duration
        if (/$cmd_opts{ani_dur}/) {
            ($run_opts_href->{ani_dur} = $_) =~
                s/$cmd_opts{ani_dur}//i;
        }

        # .avi encoding options for MPEG-4 bitrate in kbit/s.
        if (/$cmd_opts{kbps}/) {
            ($run_opts_href->{kbps} = $_) =~
                s/$cmd_opts{kbps}//i;
        }

        # .mp4 encoding options for H.264 constant rate factor.
        if (/$cmd_opts{crf}/) {
            ($run_opts_href->{crf} = $_) =~
                s/$cmd_opts{crf}//i;
        }

        # Reporting levels of ImageMagick and FFmpeg
        if (/$cmd_opts{verbose}/) {
            $run_opts_href->{is_verbose} = 1;
        }

        # The front matter won't be displayed at the beginning of the program.
        if (/$cmd_opts{nofm}/) {
            $run_opts_href->{is_nofm} = 1;
        }

        # The shell won't be paused at the end of the program.
        if (/$cmd_opts{nopause}/) {
            $run_opts_href->{is_nopause} = 1;
        }
    }
    rm_duplicates($run_opts_href->{ani_fmts});

    return;
}


sub animate_images {
    # """Run the rasters_to_anims method of Animate."""

    my $run_opts_href = shift;
    my $animate = Animate->new();

    # Notification
    if (not $run_opts_href->{img_dir}[0]) {
        print "No raster directory found.\n";
        return;
    }
    my %notifs = (
        img_dir => {
            key => 'Directory',
            val => $run_opts_href->{img_dir}[0],
        },
        seq_bname => {
            key => 'Sequential basename',
            val => $run_opts_href->{seq_bname},
        },
        img_fmt => {
            key => 'Raster format',
            val => $run_opts_href->{img_fmt},
        },
        ani_bname => {
            key => 'Animation basename',
            val => $run_opts_href->{ani_bname},
        },
        ani_fmts => {
            key => 'Animation format'.(
                $run_opts_href->{ani_fmts}[1] ? 's' : ''
            ),
            val => join(', ', @{$run_opts_href->{ani_fmts}}),
        },
        ani_dur => {
            key => 'Animation duration',
            val => $run_opts_href->{ani_dur},
        },
        verb => {
            key => 'Boolean toggle for verbose mode',
            val => $run_opts_href->{is_verbose},
        },
        # Below: optional
        kbps => {
            key => '(.avi) MPEG-4 bitrate in kbit/s',
            val => $run_opts_href->{kbps},
        },
        crf => {
            key => '(.mp4) H.264 constant rate factor',
            val => $run_opts_href->{crf},
        },
    );
    my @to_be_notifed = qw(
        img_dir
        seq_bname
        img_fmt
        ani_bname
        ani_fmts
        ani_dur
    );
    foreach (@{$run_opts_href->{ani_fmts}}) {
        push @to_be_notifed, 'kbps' if /avi/i;
        push @to_be_notifed, 'crf'  if /mp4/i;
    }
    push @to_be_notifed, 'verb';

    my $_lengthiest = '';
    foreach (keys %notifs) {
        $_lengthiest = $notifs{$_}{key}
            if length $_lengthiest < length $notifs{$_}{key};
    }
    my $_conv = '%-'.(length $_lengthiest).'s';
    print "Animation will be performed as:\n";
    print "-" x 70, "\n";
    foreach (@to_be_notifed) {
        printf(
            "$_conv => %s\n",
            $notifs{$_}{key},
            $notifs{$_}{val},
        );
    }
    print "-" x 70, "\n";

    # Apply the user-specified animation options.
    foreach (@{$run_opts_href->{ani_fmts}}) {
        $animate->Ctrls->set_gif_switch('on') if /gif/i;
        $animate->Ctrls->set_avi_switch('on') if /avi/i;
        $animate->Ctrls->set_mp4_switch('on') if /mp4/i;
    }
    $animate->FileIO->set_seq_bname($run_opts_href->{seq_bname});
    $animate->FileIO->set_ani_bname($run_opts_href->{ani_bname});
    $animate->Ctrls->set_duration($run_opts_href->{ani_dur});
    $animate->Ctrls->set_avi_kbps($run_opts_href->{kbps});
    $animate->Ctrls->set_mp4_crf($run_opts_href->{crf});
    $animate->Ctrls->set_mute($run_opts_href->{is_verbose} ? 'off' : 'on');

    # Perform animation.
    $animate->rasters_to_anims(
        # img_dir: The rasters_to_anims routine was initially designed
        # for phitar, where multiple directories are examined in order.
        # Accordingly, the raster directory here should also be passed
        # as an array reference (but now the aref contains only one elem).
        $run_opts_href->{img_dir}, # aref, not a string
        # The raster file format to be animated.
        $run_opts_href->{img_fmt},
    );

    return;
}


sub img2ani {
    # """img2ani main routine"""

    if (@ARGV) {
        my %prog_info = (
            titl       => basename($0, '.pl'),
            expl       => 'Animate raster images',
            vers       => $VERSION,
            date_last  => $LAST,
            date_first => $FIRST,
            auth       => {
                name => 'Jaewoong Jang',
#                posi => '',
#                affi => '',
                mail => 'jangj@korea.ac.kr',
            },
        );
        my %cmd_opts = ( # Command-line opts
            img_dir   => qr/-?-(?:img_)?dir\s*=\s*/i,
            seq_bname => qr/-?-seq_bname\s*=\s*/i,
            img_fmt   => qr/-?-img(?:_fmt)?\s*=\s*/i,
            ani_bname => qr/-?-ani_bname\s*=\s*/i,
            ani_fmts  => qr/-?-ani(?:_fmt)?s?\s*=\s*/i,
            ani_dur   => qr/-?-(?:ani_)?dur(?:ation)?\s*=\s*/i,
            kbps      => qr/-?-kbps\s*=\s*/,
            crf       => qr/-?-crf\s*=\s*/,
            verbose   => qr/-?-verb(?:ose)?\b/i,
            nofm      => qr/-?-nofm\b/i,
            nopause   => qr/-?-nopause\b/i,
        );
        my %run_opts = ( # Program run opts
            img_dir    => [getcwd()],
            seq_bname  => '',
            img_fmt    => 'png',
            ani_bname  => '',
            ani_fmts   => ['gif'],
            ani_dur    => 5, # second
            kbps       => 1000,
            crf        => 18,
            is_verbose => 0,
            is_nofm    => 0,
            is_nopause => 0,
        );

        # ARGV validation and parsing
        validate_argv(\@ARGV, \%cmd_opts);
        parse_argv(\@ARGV, \%cmd_opts, \%run_opts);

        # Notification - beginning
        show_front_matter(\%prog_info, 'prog', 'auth')
            unless $run_opts{is_nofm};

        # Main
        animate_images(\%run_opts);

        # Notification - end
        show_elapsed_real_time("\n");
        pause_shell()
            unless $run_opts{is_nopause};
    }

    system("perldoc \"$0\"") if not @ARGV;

    return;
}


img2ani();
__END__

=head1 NAME

img2ani - Animate raster images

=head1 SYNOPSIS

    perl img2ani.pl [-img_dir=directory] [-seq_bname=string | re!<regex>!]
                    [-img_fmt=format] [-ani_bname=string] [-ani_fmts=format ...]
                    [-ani_dur=int] [-kbps=int] [-crf=int]
                    [-verbose] [-nofm] [-nopause]

=head1 DESCRIPTION

    By wrapping ImageMagick and FFmpeg, this Perl program helps animating
    sequential raster images. img2ani uses Animate.pm, a Moose class
    written by the author:
        img2ani.pl --- Animate.pm --- ImageMagick, FFmpeg

    img2ani can be particularly useful if you:
    - do not know how to animate raster images
    - do not want to learn how to animate raster images
    - do not want to designate frame rates in a manual fashion
    - do not want to manually set the animation/video resolution
      (img2ani fetches the raster pixel size and determines
      the animation pixel size)
    - want to animate rasters to .gif, .avi, and .mp4 at the same time
    - want to use Perl regexes rather than format specifiers such as %03d

    By using eps2img, a sister program written by the author,
    .eps files can also be animated. See "SEE ALSO" below.

=head1 OPTIONS

    -img_dir=directory (short form: -dir, default: current working dir)
        The directory in which to-be-animated sequential rasters are stored.

    -seq_bname=string | re!<regex>! (default: empty)
        The basename of sequential raster files. For instance,
        if you have raster images called 'triv-001.png', 'triv-002.png', ...,
        enter '-seq_bname=triv-' or '-seq_bname=triv', or even '-seq_bname=tri'.
        If you have files '001.png', '002.png', ..., enter '-seq_bname='
        (i.e. nothing is followed by =) or do not use the option at all.
        A Perl regex can also be used. Enter your regex as:
        -seq_bname=re!<your_regex_here>!
        -seq_bname=re!(mame)?[-_]?shiba[a-zA-Z]+[-_]?!
        Your regex will be interpolated into a case-insensitive regex ref.
        Note that in the above example, [-] is input rather than [\-];
        the characters you input are first interpreted by your shell
        and are simply passed to a regex ref. Therefore, some regex commands
        primarily used by the shell (e.g. |) cannot be used,
        subject to your operating system.

    -img_fmt=format (short form: -img, default: png)
        The raster format to be animated. Choose one of:
        png
        jpg

    -ani_bname=string (default: empty)
        The basename of animations. Unless otherwise specified,
        the matched sequential basename will be used.

    -ani_fmts=format ... (short form: -ani, default: gif)
        Output animation/video formats. Multiple formats are separated
        by the comma (,).
        all (all formats below)
        gif
        avi
        mp4

    -ani_dur=int (short form: -dur, default: 5)
        The animation duration expressed in second. Only positive integers
        are allowed. The frame rate will be automatically calculated
        using this duration.

    -kbps=int (default: 1000, sane range 200-1000)
        .avi encoding options for MPEG-4 bitrate in kbit/s.

    -crf=int (default: 18, sane range 15-25)
        .mp4 encoding options for H.264 constant rate factor.

    -verbose (short form: -verb)
        The wrapped programs will display processing results.

    -nofm
        The front matter will not be displayed at the beginning of the program.

    -nopause
        The shell will not be paused at the end of the program.
        Use it for a batch run.

=head1 EXAMPLES

    perl img2ani.pl -img_dir=./inu -seq_bname=shiba -ani=all -verb
    perl img2ani.pl -img_dir=./triv -seq_bname=trivials -ani_bname=nontrivials
    perl img2ani.pl -img_dir=./rf -seq_bname=re!lin(ear)?acc?! -ani_bname=linac
    perl img2ani.pl -img_dir=./samples -seq_bname=rsz1280x720_DSC -img_fmt=jpg -ani_bname=ny_harbor -ani_fmts=all
    perl img2ani.pl -img_dir=./samples -seq_bname=shinobazu -img_fmt=jpg -ani_fmts=all -ani_dur=7

=head1 REQUIREMENTS

    Perl 5
        Moose, namespace::autoclean
    For animation
        ImageMagick, FFmpeg

=head1 SEE ALSO

L<img2ani on GitHub|https://github.com/jangcom/img2ani>

Want to animate .eps files? Check out the sister program:
L<eps2img on GitHub|https://github.com/jangcom/eps2img>

=head1 AUTHOR

Jaewoong Jang <jangj@korea.ac.kr>

=head1 COPYRIGHT

Copyright (c) 2019 Jaewoong Jang

=head1 LICENSE

This software is available under the MIT license;
the license information is found in 'LICENSE'.

=cut
