process MALT_RUN {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/malt:0.62--hdfd78af_0' :
        'biocontainers/malt:0.62--hdfd78af_0' }"

    input:
    tuple val(meta), path(fastqs)
    path index
    val mode

    output:
    tuple val(meta), path("*.rma6")                                , emit: rma6
    tuple val(meta), path("*.{tab,text,sam}{,.gz}"), optional:true , emit: alignments
    tuple val(meta), path("*.log")                                 , emit: log
    path "versions.yml"                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    assert mode in ['Unknown', 'BlastN', 'BlastP', 'BlastX', 'Classifier']
    """
    malt-run \\
        --numThreads $task.cpus \\
        --mode $mode \\
        --verbose \\
        --output . \\
        $args \\
        --inFile ${fastqs.join(' ')} \\
        --index $index/ |& tee ${prefix}-malt-run.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        malt: \$( malt-run --help |& sed '/version/!d; s/.*version //; s/,.*//' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}-malt-run.log
    touch ${prefix}.rma6
    touch ${prefix}.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        malt: \$( malt-run --help |& sed '/version/!d; s/.*version //; s/,.*//' )
    END_VERSIONS
    """
}
