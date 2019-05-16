# img2ani

<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:" />
</head>

<body>



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#SYNOPSIS">SYNOPSIS</a></li>
  <li><a href="#DESCRIPTION">DESCRIPTION</a></li>
  <li><a href="#OPTIONS">OPTIONS</a></li>
  <li><a href="#EXAMPLES">EXAMPLES</a></li>
  <li><a href="#REQUIREMENTS">REQUIREMENTS</a></li>
  <li><a href="#SEE-ALSO">SEE ALSO</a></li>
  <li><a href="#AUTHOR">AUTHOR</a></li>
  <li><a href="#COPYRIGHT">COPYRIGHT</a></li>
  <li><a href="#LICENSE">LICENSE</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>img2ani - Animate raster images</p>

<h1 id="SYNOPSIS">SYNOPSIS</h1>

<pre><code>    perl img2ani.pl [-img_dir=directory [-seq_bname=string | re!&lt;regex&gt;!]
                    [-img_fmt=format] [-ani_bname=string] [-ani_fmts=format ...]
                    [-ani_dur=int] [-kbps=int] [-crf=int]
                    [-verbose] [-nofm] [-nopause]</code></pre>

<h1 id="DESCRIPTION">DESCRIPTION</h1>

<pre><code>    By wrapping ImageMagick and FFmpeg, this Perl program helps animating
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
    .eps files can also be animated. See &quot;SEE ALSO&quot; below.</code></pre>

<h1 id="OPTIONS">OPTIONS</h1>

<pre><code>    -img_dir=directory (short form: -dir, default: current working dir)
        The directory in which to-be-animated sequential rasters are stored.

    -seq_bname=string | re!&lt;regex&gt;! (default: empty)
        The basename of sequential raster files. For instance,
        if you have raster images called &#39;triv-001.png&#39;, &#39;triv-002.png&#39;, ...,
        enter &#39;-seq_bname=triv-&#39; or &#39;-seq_bname=triv&#39;, or even &#39;-seq_bname=tri&#39;.
        If you have files &#39;001.png&#39;, &#39;002.png&#39;, ..., enter &#39;-seq_bname=&#39;
        (i.e. nothing is followed by =) or do not use the option at all.
        A Perl regex can also be used. Enter your regex as:
        -seq_bname=re!&lt;your_regex_here&gt;!
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
        Use it for a batch run.</code></pre>

<h1 id="EXAMPLES">EXAMPLES</h1>

<pre><code>    perl img2ani.pl -img_dir=./inu -seq_bname=shiba -ani=all -verb
    perl img2ani.pl -img_dir=./triv -seq_bname=trivials -ani_bname=nontrivials
    perl img2ani.pl -img_dir=./rf -seq_bname=re!lin(ear)?acc?! -ani_bname=linac
    perl img2ani.pl -img_dir=./samples -seq_bname=rsz1280x720_DSC -img_fmt=jpg -ani_bname=ny_harbor -ani_fmts=all
    perl img2ani.pl -img_dir=./samples -seq_bname=shinobazu -img_fmt=jpg -ani_fmts=all -ani_dur=7</code></pre>

<h1 id="REQUIREMENTS">REQUIREMENTS</h1>

<pre><code>    Perl 5
        Moose, namespace::autoclean
    For animation
        ImageMagick, FFmpeg</code></pre>

<h1 id="SEE-ALSO">SEE ALSO</h1>

<p><a href="https://github.com/jangcom/img2ani">img2ani on GitHub</a></p>

<p>Want to animate .eps files? Check out the sister program: <a href="https://github.com/jangcom/eps2img">eps2img on GitHub</a></p>

<h1 id="AUTHOR">AUTHOR</h1>

<p>Jaewoong Jang &lt;jangj@korea.ac.kr&gt;</p>

<h1 id="COPYRIGHT">COPYRIGHT</h1>

<p>Copyright (c) 2019 Jaewoong Jang</p>

<h1 id="LICENSE">LICENSE</h1>

<p>This software is available under the MIT license; the license information is found in &#39;LICENSE&#39;.</p>


</body>

</html>
