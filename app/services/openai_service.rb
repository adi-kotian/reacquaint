require "open-uri"
require "pdf-reader"

class OpenaiService
  def initialize(attrs = {})
    @selected_prerequisite = attrs[:selected_prerequisite]
    @compatible_response = attrs[:compatible_response]
    @tender = attrs[:tender]
    @client = OpenAI::Client.new
  end

  def categories
    ["Health & Safety"]
  end

  # Personae
  def owner_persona
    <<~PERSONA
    You are a Tender Analysis & Writing Expert for Building and Construction.

    You specialize in reading, evaluating, and writing tender documents to ensure they align with industry best practices, regulatory requirements,
    and project feasibility. Your expertise lies in identifying gaps, inconsistencies, and risks within tender documents and refining them to enhance clarity, compliance, and enforceability.

    Your Key Skills & Approach:
      •	Tender Analysis: You critically assess tender documents to identify missing, vague, or contradictory requirements that could create project risks.
      •	Regulatory & Contractual Compliance: You ensure tenders align with relevant standards, such as FIDIC, NEC, JCT, and local procurement regulations.
      •	Best Practice Enhancement: You refine tender documents to incorporate clear deliverables, well-defined evaluation criteria, and structured pricing models.
      •	Strategic Tender Writing: You rewrite tenders to improve precision, readability, and alignment with project objectives.
      •	Bid Optimization: You assist bidders in crafting compelling, compliant responses that maximize their scoring potential.

      You work methodically, using structured frameworks such as risk assessments, scoring matrices, and compliance checklists.
      Your recommendations balance legal precision, commercial viability, and practical execution to ensure tenders are robust, fair, and effective.
    PERSONA
  end

  def bidder_persona
    <<~PERSONA
    You are an expert in crafting compelling, compliant, and strategically optimized bid responses for construction, civil engineering, and infrastructure tenders.
    Your expertise lies in translating technical requirements into persuasive proposals that align with evaluation criteria, maximize scoring potential,
    and differentiate your bid from competitors.

    Your Key Skills & Approach:
	  •	 Bid Strategy & Win Themes: You develop tailored bid strategies that highlight competitive strengths, unique value propositions, and alignment with client priorities.
	  •	 Compliance & Evaluation Alignment: You meticulously ensure bid responses meet all contractual, technical, and regulatory requirements (e.g., FIDIC, NEC, JCT).
	  •	 Persuasive & Clear Writing: You craft clear, concise, and engaging responses that effectively communicate capability, experience, and project approach.
	  •	 Technical & Commercial Integration: You collaborate with technical and commercial teams to produce well-balanced bids that are both technically sound and commercially competitive.
	  • Risk & Gap Analysis: You assess tender documents to identify risks, ambiguities, and compliance challenges, ensuring mitigation strategies are embedded in the bid.
	  •	Bid Review & Scoring Optimization: You refine submissions to enhance readability, clarity, and alignment with scoring methodologies.

    You work systematically, leveraging bid frameworks, compliance checklists, and evaluation matrices to ensure every response is compelling, precise, and aligned with the client’s objectives.
    Your approach balances persuasive writing with technical accuracy, ensuring that bids are not only compliant but also stand out as winning proposals.
    PERSONA
  end

  # Tender & Selected Prerequisites (Original)
  def analyse
    instructions = <<~INSTRUCTIONS
    You are analyzing a requirement description from a tender specifications document. This description is typically copy-pasted from a boilerplate template
    and may not accurately reflect the specific needs of the project. Your goal is to assess and enhance its clarity, alignment with industry best practices,
    and relevance to the project’s objectives.

    Analysis Steps:
    1. Compare the inputted requirement description with:
      •	The requirement title (to ensure adherence to industry best practices for that type of requirement).
      •	The project synopsis (to evaluate alignment with the project’s objectives and intended outcomes).
	  2. Identify gaps and areas for improvement based on:
      •	Industry standards and best practices relevant to the requirement title.
      •	The specific context and goals outlined in the project synopsis.
	  3.Draft a concise report (max. 250 words) structured with bullet points, spacings, and subheadings.
      •	Highlight missing details, ambiguities, or inconsistencies.
      •	Suggest specific improvements to enhance clarity, completeness, and relevance.

    Maintain a professional and objective tone while ensuring the recommendations are practical and actionable.

    The inputted description is:

    #{@selected_prerequisite.description}

    The requirement title is:

    #{@selected_prerequisite.prerequisite.name}

    The project synopsis is:

    #{@selected_prerequisite.tender.synopsis}
    INSTRUCTIONS

    chatgpt_response = @client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "user", content: owner_persona},
        { role: "user", content: instructions}
      ]
    })
    @result = chatgpt_response["choices"][0]["message"]["content"]
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
    markdown.render(@result)
  end

  def rewrite
    instructions = <<~INSTRUCTIONS
    Rewrite the inputted description based on the result of the analysis.
    Rewrite to be as comprehensive as possible but do not exceed 1000 words.
    Use formatting for headers, italics, bolding, and bullet points as appropriate.
    Have spacing to improve readability.

    The inputted description is:

    #{@selected_prerequisite.description}

    The analysis is:

    #{@selected_prerequisite.analysis}
    INSTRUCTIONS


    chatgpt_response = @client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "user", content: owner_persona},
        { role: "user", content: instructions}
      ]
    })
    @result = chatgpt_response["choices"][0]["message"]["content"]
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
    markdown.render(@result)
  end

  # Tender & Selected Prerequisites (New)
  def spq_read
    url = @tender.document.url
    file = URI.open(url)
    pdf = PDF::Reader.new(file)
    pdf_text = pdf.pages.map(&:text).join("\n\n")
    Prerequisite.find_each do |prerequisite|
      instructions = <<~INSTRUCTIONS
      Analyze the provided PDF text and extract only the content directly relevant to the given prerequisite title: #{prerequisite.name}.
      Focus on sections, paragraphs, or points that explicitly mention, explain, or build upon this prerequisite.
      Ignore unrelated or loosely connected content. If relevant information is scattered, consolidate it into a structured summary.
      Retain key details, technical terms, and any examples that clarify the prerequisite’s role.
      Ensure coherence and completeness while avoiding redundant or extraneous material.

      The PDF text is #{pdf_text}
      INSTRUCTIONS

      chatgpt_response = @client.chat(parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: owner_persona},
          { role: "user", content: instructions}
        ]
      })
      @result = chatgpt_response["choices"][0]["message"]["content"]
      renderer = Redcarpet::Render::HTML.new
      markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
      SelectedPrerequisite.create(description: markdown.render(@result), tender: @tender, prerequisite: prerequisite)
      Turbo::StreamsChannel.broadcast_replace_to(
        "tender_#{@tender.id}_links",
        target: "spq-index-links",
        partial: "tenders/spq_index_links",
        locals: { tender: @tender }
      )
    end
  end

  def tender_brief
    concat_descriptions = ""
    @tender.selected_prerequisites do |spq|
      input = "
      #{spq.prerequisite.name}

      #{spq.description}
      "
      concat_descriptions += input
    end
      instructions = <<~INSTRUCTIONS
      Task:
        1.	Review the Tender Requirements
        •	Carefully read the consolidated descriptions of all prerequisites and requirements provided in the tender document.
        2.	Summarize Key Information
        •	Create a one-page executive summary (tender brief) that highlights essential details.
        •	Structure the summary into the following sections:
        •	Requirements: Core eligibility criteria and mandatory conditions.
        •	Key Points & Considerations: Important aspects, unique conditions, or critical evaluation criteria.
        •	Other Noteworthy Information: Additional details that may impact a bidder’s decision.
        3.	Objective:
        •	Ensure the summary allows prospective bidders to quickly assess if the tender is relevant and worth pursuing.
        •	Do not return thought process or any other commentary. Only return the executive summary.

      Source Material:
        •	The consolidated descriptions of all prerequisites and requirements are: #{concat_descriptions}.
      INSTRUCTIONS

      chatgpt_response = @client.chat(parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: owner_persona},
          { role: "user", content: instructions}
        ]
      })
      @result = chatgpt_response["choices"][0]["message"]["content"]
      renderer = Redcarpet::Render::HTML.new
      markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
      @tender.synopsis = markdown.render(@result)
      @tender.save
      Turbo::StreamsChannel.broadcast_replace_to(
        "tender_#{@tender.id}_links",
        target: "tender-synopsis",
        partial: "tenders/synopsis",
        locals: { tender: @tender }
      )
  end

  # Submission & Compatible Responses (Original)
  def write
    instructions = <<~INSTRUCTIONS
    You are reviewing a tender document to assess its requirements and draft a strategically optimized bid response.
    Your goal is to ensure that the response is compliant, compelling, and aligned with evaluation criteria, maximizing its scoring potential.

    Analysis & Response Writing Steps:

    1. Requirement Analysis (do not return this but use it in drafting the bid response)
      •	Compare the requirement description with:
      •	The project synopsis (to ensure alignment with the overall project).
      •	The requirement title objectives (to highlight how the bid meets the title's goals).
      •	Identify ambiguities, missing details, or areas where clarification is needed.
      •	Assess the requirement against industry standards (e.g., FIDIC, NEC, JCT) and best practices.

    2. Bid Strategy & Optimization (do not return this but use it in drafting the bid response)
      •	Identify key win themes that differentiate the bid (e.g., innovation, sustainability, risk mitigation, cost-effectiveness).
      •	Ensure the response effectively addresses technical, commercial, and compliance aspects.
      •	Structure the bid to enhance clarity, readability, and persuasive impact.

    3. Drafting the Bid Response (Max. 250 Words)
      •	Use a structured format with bullet points and subheadings.
      •	Clearly articulate:
        •	Understanding of the requirement (demonstrating insight into project goals).
        •	Approach & Methodology (how the bidder will deliver the requirement efficiently).
        •	Experience & Capabilities (evidence of past success, qualifications, and technical expertise).
        •	Value Proposition (how the bid offers the best solution in terms of quality, cost, and risk management).
        •	Ensure concise, professional, and persuasive writing.

    Your recommendations should balance strategic persuasion and technical accuracy, ensuring the bid is compliant, competitive,
    and compelling while addressing all requirements effectively.

    The requirement description is:

    #{@selected_prerequisite.description}

    The requirement title is:

    #{@selected_prerequisite.prerequisite.name}

    The project synopsis is:

    #{@selected_prerequisite.tender.synopsis}
    INSTRUCTIONS

    chatgpt_response = @client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "user", content: bidder_persona},
        { role: "user", content: instructions}
      ]
    })
    @result = chatgpt_response["choices"][0]["message"]["content"]
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
    markdown.render(@result)
  end

  def score
    instructions = <<~INSTRUCTIONS
    You are reviewing a bidder's responses to requirements(selected prerequisites)
    and their descriptions on a project based on the following rubrics.
    Match the name on the rubric to the requirement title to which the response is made for the selected prerequisite
    and generate a numeric score ranging from 1 -100 based on how closely the response succeeds in satisfiying the conditions.
    Now take each score and generate an overall score that is the average of all scores.
    Please do not return any text, only an integer score between 1 - 100.

    The requirement description is:

    #{@selected_prerequisite.description}

    The requirement title is:

    #{@selected_prerequisite.prerequisite.name}r
    INSTRUCTIONS

    chatgpt_response = @client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "user", content: bidder_persona},
        { role: "user", content: instructions}
      ]
    })
    @result = chatgpt_response["choices"][0]["message"]["content"]
  end

  # Submission & Compatible Responses (New)


end
